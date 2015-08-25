require 'spec_helper'

describe "Checkout", type: :feature do
  let!(:country) do
    create(:country, name: "United States", states_required: true)
  end
  let!(:state) { create(:state, name: "Ohio", country: country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let(:product) { create(:product, name: "RoR Mug") }
  let(:variant) { create(:variant) }

  stub_authorization!

  before { product.parts.push variant }

  shared_context "purchases product with part included" do
    before do
      add_product_to_cart
      click_button "Checkout"

      fill_in "order_email", with: "ryan@spreecommerce.com"
      fill_in_address

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("delivery"))
      page.should have_content(variant.product.name)

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("payment"))

      click_button "Save and Continue"
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      page.should have_content(variant.product.name)
    end
  end

  context "backend order shipments UI", js: true do
    context "ordering only the product assembly" do
      include_context "purchases product with part included"

      it "views parts bundled as well" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end

    context "ordering assembly and the part as individual sale" do
      before do
        visit spree.root_path
        click_link variant.product.name
        click_button "add-to-cart-button"
      end
      include_context "purchases product with part included"

      it "views parts bundled and not" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end
  end

  context "when a part allows User to select any variant", js: true do
    it "marks non-deferred parts as out of stock" do
      rock = create(:product_in_stock, name: "Rock",
                                       can_be_part: true)
      stick = create(:product, name: "Stick",
                               can_be_part: true)

      stick.stock_items.first.update_attribute(:backorderable, false)

      bundle = create(:product, name: "Bundle")

      create(:assemblies_part, assembly_id: bundle.id,
                               part_id: rock.master.id)
      create(:assemblies_part, assembly_id: bundle.id,
                               part_id: stick.master.id)
      bundle.reload

      visit spree.root_path
      click_link bundle.name

      within("#products") do
        expect(page).to have_content("Out of Stock")
      end
    end

    it "marks non-deferred parts as backorderable" do
      rock = create(:product_in_stock, name: "Rock",
                                       can_be_part: true)
      stick = create(:product, name: "Stick",
                               can_be_part: true)

      stick.stock_items.first.update_attribute(:backorderable, true)

      bundle = create(:product, name: "Bundle")

      create(:assemblies_part, assembly_id: bundle.id,
                               part_id: rock.master.id)
      create(:assemblies_part, assembly_id: bundle.id,
                               part_id: stick.master.id)

      bundle.reload

      visit spree.root_path
      click_link bundle.name

      within("#products") do
        expect(page).to have_content("Backorderable")
      end
    end

    it "does not allow selection of variants that are out of stock" do
      red_option = create(:option_value, presentation: "Red")
      blue_option = create(:option_value, presentation: "Blue")
      green_option = create(:option_value, presentation: "Green")

      option_type = create(:option_type,
                           presentation: "Color",
                           name: "color",
                           option_values: [
                             red_option,
                             blue_option,
                             green_option
                           ])

      shirt = create(:product_in_stock,
                     name: "Shirt",
                     option_types: [option_type],
                     can_be_part: true)

      red = create(:variant_in_stock,
                   product: shirt,
                   sku: "PART-RED",
                   option_values: [red_option])
      blue = create(:variant,
                    product: shirt,
                    sku: "PART-BLUE",
                    option_values: [blue_option])
      green = create(:variant,
                     product: shirt,
                     sku: "PART-GREEN",
                     option_values: [green_option])

      blue.stock_items.first.update_attribute(:backorderable, true)
      green.stock_items.first.update_attribute(:backorderable, false)

      bundle = create(:product, name: "Bundle")

      create(:assemblies_part, assembly_id: bundle.id,
                               part_id: shirt.master.id,
                               variant_selection_deferred: true)
      bundle.reload

      visit spree.root_path
      click_link bundle.name

      first_selectable = bundle.assemblies_parts.first.id

      within("#options_selected_variants_#{first_selectable}") do
        expect(page).to have_css("option[value='#{red.id}']")
        expect(page).to have_css("option[value='#{blue.id}']")
        expect(page).to(
          have_css("option[value='#{green.id}'][disabled='disabled']")
        )
      end
    end

    it "shows the part the User selected at all stages of checkout" do
      red_option = create(:option_value, presentation: "Red")
      blue_option = create(:option_value, presentation: "Blue")

      option_type = create(:option_type,
                           presentation: "Color",
                           name: "color",
                           option_values: [red_option, blue_option])

      shirt = create(:product_in_stock,
                     name: "Shirt",
                     option_types: [option_type],
                     can_be_part: true)

      create(:variant_in_stock,
             product: shirt,
             sku: "PART-RED",
             option_values: [red_option])
      create(:variant_in_stock,
             product: shirt,
             sku: "PART-BLUE",
             option_values: [blue_option])

      bundle = create(:product, name: "Bundle")

      create(:assemblies_part,
             assembly_id: bundle.id,
             part_id: shirt.master.id,
             variant_selection_deferred: true)
      bundle.reload

      visit spree.root_path
      click_link bundle.name

      select "Color: Blue", from: "Variant"
      click_button "add-to-cart-button"

      click_button "Checkout"

      fill_in "order_email", with: "ryan@spreecommerce.com"
      fill_in_address

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("delivery"))
      expect(page).to have_content(shirt.name)
      expect(page).to have_content("Color: Blue")

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("payment"))

      click_button "Save and Continue"
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      expect(page).to have_content(shirt.name)
      expect(page).to have_content("Color: Blue")
    end
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", with: "Ryan"
    fill_in "#{address}_lastname", with: "Bigg"
    fill_in "#{address}_address1", with: "143 Swan Street"
    fill_in "#{address}_city", with: "Richmond"
    select "Ohio", from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: "12345"
    fill_in "#{address}_phone", with: "(555) 555-5555"
  end

  def add_product_to_cart
    visit spree.root_path
    click_link product.name
    click_button "add-to-cart-button"
  end
end
