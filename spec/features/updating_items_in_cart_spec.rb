require "spec_helper"

describe "Updating items in the cart", type: :feature do
  context "when updating a bundle's quantity" do
    context "when none of the bundle items are packs or have options" do
      specify "the quantities are multiplied by the bundle's new quantity" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)
        shirt = create(:product_in_stock, name: "Shirt",
                                          sku: "SHIRT",
                                          can_be_part: true)

        add_part_to_bundle(bundle, keychain.master)
        add_part_to_bundle(bundle, shirt.master)

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail") do
          find("input").set 2
        end

        click_button "update-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='2']")
          expect(page).to have_content("(2) Keychain (KEYCHAIN)")
          expect(page).to have_content("(2) Shirt (SHIRT)")
        end
      end
    end

    context "when one of the variants is a pack" do
      specify "the pack quantity is multiplied by the bundle's new quantity" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)

        _shirt, shirts_by_size = create_bundle_product_with_options(
          name: "Shirt",
          sku: "SHIRT",
          option_type: "Size",
          option_values: ["Small"]
        )

        add_part_to_bundle(bundle, keychain.master, count: 2)
        add_part_to_bundle(bundle, shirts_by_size["small"])

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail") do
          find("input").set 2
        end

        click_button "update-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='2']")
          expect(page).to have_content("(4) Keychain (KEYCHAIN)")
          expect(page).to have_content("(2) Shirt (Size: Small) (SHIRT-SMALL)")
        end
      end
    end

    context "when a bundle items has a variant (that is not user-selectable)" do
      specify "the variant quantity is multiplied by the new bundle quantity" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)

        _shirt, shirts_by_size = create_bundle_product_with_options(
          name: "Shirt",
          sku: "SHIRT",
          option_type: "Size",
          option_values: ["Small"]
        )

        add_part_to_bundle(bundle, keychain.master)
        add_part_to_bundle(bundle, shirts_by_size["small"])

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail") do
          find("input").set 2
        end

        click_button "update-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='2']")
          expect(page).to have_content("(2) Keychain (KEYCHAIN)")
          expect(page).to have_content("(2) Shirt (Size: Small) (SHIRT-SMALL)")
        end
      end
    end

    context "when one of the bundle items has a user-selectable variant" do
      specify "the variant quantity is multiplied by the new bundle quantity" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)

        shirt, _shirts_by_size = create_bundle_product_with_options(
          name: "Shirt",
          sku: "SHIRT",
          option_type: "Size",
          option_values: ["Small", "Medium"]
        )

        add_part_to_bundle(bundle, keychain.master, count: 1)
        add_part_to_bundle(
          bundle,
          shirt.master,
          variant_selection_deferred: true
        )

        visit spree.product_path(bundle)

        select "Size: Medium", from: "Variant"

        click_button "add-to-cart-button"

        within("#cart-detail") do
          find("input").set 2
        end

        click_button "update-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='2']")
          expect(page).to have_content("(2) Keychain (KEYCHAIN)")
          expect(page).to(
            have_content("(2) Shirt (Size: Medium) (SHIRT-MEDIUM)")
          )
        end
      end
    end
  end

  def create_bundle_product_with_options(args)
    option_type_presentation = args.fetch(:option_type)
    option_value_presentations = args.fetch(:option_values)
    option_values = option_value_presentations.map do |presentation|
      create(:option_value, presentation: presentation)
    end
    option_type = create(:option_type,
      presentation: option_type_presentation,
      name: option_type_presentation.downcase,
      option_values: option_values)
    product_attributes = args.slice(:name, :sku).merge(
      option_types: [option_type],
      can_be_part: true
    )
    product = create(:product, product_attributes)

    variants = variants_by_option(product, option_values)

    [product, variants]
  end

  def variants_by_option(product, option_values)
    option_values.each_with_object({}) do |value, hash|
      hash[value.presentation.downcase] = create(
        :variant_in_stock,
        product: product,
        sku: "#{product.sku}-#{value.presentation.upcase}",
        option_values: [value]
      )
    end
  end

  def add_part_to_bundle(bundle, variant, options = {})
    attributes = options.reverse_merge(
      assembly_id: bundle.id,
      part_id: variant.id,
    )
    create(:assemblies_part, attributes).tap do |_part|
      bundle.reload
    end
  end
end
