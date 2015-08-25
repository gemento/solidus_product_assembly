require 'spec_helper'

describe "Managing parts for a product bundle", type: :feature, js: true do
  stub_authorization!

  let!(:tshirt) { create(:product, :name => "T-Shirt") }
  let!(:mug) { create(:product, :name => "Mug", can_be_part: true) }

  context "when searching for parts" do
    before do
      visit spree.admin_product_path(tshirt)
      click_on "Parts"
    end

    it "returns empty results when there is no query" do
      fill_in "searchtext", with: ""
      click_on "Search"

      page.should have_content("No Match Found.")
    end

    it "displays no-match feedback when it does not find any products" do
      fill_in "searchtext", with: "Foo"
      click_on "Search"

      page.should have_content("No Match Found.")
    end

    it "shows any products that were found" do
      fill_in "searchtext", with: mug.name
      click_on "Search"

      page.should have_content(mug.name)
    end
  end

  context "when adding parts to a bundle" do
    it "allows adding a product with no variants" do
      visit spree.admin_product_path(tshirt)
      click_on "Parts"
      fill_in "searchtext", with: mug.name
      click_on "Search"

      within("#search_hits") { click_on "Select" }
      page.should have_content(mug.sku)
    end

    context "when a part has multiple variants" do
      def build_option(options)
        option_type_name = options.fetch(:type)
        option_type = create(:option_type,
          presentation: option_type_name,
          name: option_type_name
        )
        option_value = options.fetch(:value)
        option_type.option_values.create(
          name: option_value.downcase,
          presentation: option_value
        )

        option_type
      end

      def build_part_with_options(product_name, option_type)
        product = create(:product,
          can_be_part: true,
          name: product_name,
          option_types: [option_type]
        )
        create(:variant,
          product: product,
          option_values: option_type.option_values
        )
      end

     it "allows a specific variant to be selected as part of the bundle" do
        bundle = create(:product)
        option = build_option(type: "Color", value: "Red")
        part = build_part_with_options("Shirt", option)

        visit spree.admin_product_path(bundle)
        click_on "Parts"
        fill_in "searchtext", with: "Shirt"
        click_on "Search"

        within("#search_hits") do
          select "Color: Red", from: "part_id"
          click_on "Select"
        end

        page.should have_content(part.sku)
      end

      it "allows admin to specify that user can select any variant" do
        bundle = create(:product)
        option = build_option(type: "Color", value: "Red")
        part = build_part_with_options("Shirt", option)

        visit spree.admin_product_path(bundle)
        click_on "Parts"
        fill_in "searchtext", with: "Shirt"
        click_on "Search"

        within("#search_hits") do
          select Spree.t(:user_selectable), from: "part_id"
          fill_in "part_count", with: 666
          click_on "Select"
        end

        within("#product_parts") do
          page.should have_content("Shirt")
          page.should have_content(part.product.sku)
          page.should have_content(Spree.t(:user_selectable))

          input = find_field("count")
          input[:value].should eq("666")
        end
      end
    end
  end

  it "allows parts to be removed from the bundle" do
    visit spree.admin_product_path(tshirt)
    click_on "Parts"
    fill_in "searchtext", with: mug.name
    click_on "Search"

    within("#search_hits") { click_on "Select" }
    page.should have_content(mug.sku)

    within("#product_parts") do
      find(".remove_admin_product_part_link").click

      page.should_not have_content(mug.sku)
    end
  end

  context "when updating part quantities" do
    before do
      visit spree.admin_product_path(tshirt)
      click_on "Parts"
      fill_in "searchtext", with: mug.name
      click_on "Search"
      within("#search_hits") { click_on "Select" }
    end

    it "updates the quantity to match the newly-supplied value" do
      within("#product_parts") do
        fill_in "count", with: "5"
        find(".set_count_admin_product_part_link").click

        expect(find_field('count').value).to eq "5"
      end
    end

    it "rejects a negative quantity" do
      within("#product_parts") do
        fill_in "count", with: "-1"
        find(".set_count_admin_product_part_link").click
      end

      expect(page).to have_content("Quantity must be greater than 0")
    end

    it "rejects a part quantity of `0`" do
      within("#product_parts") do
        fill_in "count", with: "0"
        find(".set_count_admin_product_part_link").click
      end

      expect(page).to have_content("Quantity must be greater than 0")
    end

    it "rejects a non-numeric part quantity" do
      within("#product_parts") do
        fill_in "count", with: "non-numeric"
        find(".set_count_admin_product_part_link").click
      end

      expect(page).to have_content("Quantity must be greater than 0")
    end
  end
end
