require 'spec_helper'

module Spree
  describe OrderInventoryAssembly do
    describe "#verify" do
      context "when line item involves variants that are not user-selectable" do
        context "when a shipment is provided" do
          context "when the bundle is created" do
            it "produces inventory units for each item in the bundle" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end
          end

          context "when the bundle quantity is increased" do
            it "adds [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3

              line_item.update_column(:quantity, 2)
              inventory.verify(shipment)

              expect(inventory.inventory_units.count).to eq 10

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6
            end
          end

          context "when the bundle quantity is decreased" do
            it "removes [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                line_item_quantity: 2,
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(inventory.inventory_units.count).to eq 10

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6

              line_item.update_column(:quantity, 1)
              inventory.verify(shipment)

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end
          end
        end

        context "when a shipment is not provided" do
          context "when the bundle is created" do
            it "produces inventory units for each item in the bundle" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end
          end

          context "when the bundle quantity is increased" do
            it "adds [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3

              line_item.update_column(:quantity, 2)
              inventory.verify

              expect(inventory.inventory_units.count).to eq 10

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6
            end
          end

          context "when the bundle quantity is decreased" do
            it "removes [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                line_item_quantity: 2,
                parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
              )
              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify

              expect(inventory.inventory_units.count).to eq 10

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6

              line_item.update_column(:quantity, 1)
              inventory.verify

              expect(inventory.inventory_units.count).to eq 5

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end

            context "when the bundle has shipped and unshipped shipments" do
              it "removes the items from only the unshipped shipments" do
                unshipped_shipment,
                line_item,
                variants = create_line_item_for_bundle(
                  line_item_quantity: 2,
                  parts: [{ count: 1 }, { count: 1 }, { count: 3 }]
                )
                shipped_shipment = create(:shipment, state: 'shipped')
                InventoryUnit.all[0..2].each do |unit|
                  unit.update_attribute(:shipment_id, shipped_shipment.id)
                end

                inventory = OrderInventoryAssembly.new(line_item)

                line_item.update_column(:quantity, 1)
                inventory.verify

                expect(inventory.inventory_units.count).to eq 6

                unshipped_units = unshipped_shipment.inventory_units
                expect(unshipped_units.count).to eq 3
                unshipped_units.each do |unit|
                  expect(unit.variant).to eq variants[2]
                end

                shipped_units = shipped_shipment.inventory_units
                expect(shipped_units.count).to eq 3
                shipped_units[0..1].each do |unit|
                  expect(unit.variant).to eq variants[0]
                end
                expect(shipped_units[2].variant).to eq variants[1]
              end
            end
          end
        end
      end

      context "when line item involves user-selectable variants" do
        context "when a shipment is provided" do
          context "when the bundle is created" do
            it "produces inventory units for each item in the bundle" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [
                  { count: 1 },
                  { count: 1 },
                  { count: 3, variant_selection_deferred: true }
                ]
              )

              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end
          end

          context "when the bundle quantity is increased" do
            it "adds [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                parts: [
                  { count: 1 },
                  { count: 1 },
                  { count: 3, variant_selection_deferred: true }
                ]
              )

              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3

              line_item.update_column(:quantity, 2)
              inventory.verify(shipment)

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6
            end
          end

          context "when the bundle quantity is decreased" do
            it "removes [difference in quantity] sets of inventory units" do
              shipment, line_item, variants = create_line_item_for_bundle(
                line_item_quantity: 2,
                parts: [
                  { count: 1 },
                  { count: 1 },
                  { count: 3, variant_selection_deferred: true }
                ]
              )

              inventory = OrderInventoryAssembly.new(line_item)
              inventory.verify(shipment)

              expect(shipment.inventory_units_for(variants[0]).count).to eq 2
              expect(shipment.inventory_units_for(variants[1]).count).to eq 2
              expect(shipment.inventory_units_for(variants[2]).count).to eq 6

              line_item.update_column(:quantity, 1)
              inventory.verify(shipment)

              expect(shipment.inventory_units_for(variants[0]).count).to eq 1
              expect(shipment.inventory_units_for(variants[1]).count).to eq 1
              expect(shipment.inventory_units_for(variants[2]).count).to eq 3
            end
          end
        end
      end
    end

    def create_line_item_for_bundle(args)
      parts = args.fetch(:parts)
      line_item_quantity = args.fetch(:line_item_quantity, 1)
      order = create(:order, completed_at: Time.now)
      shipment = create(:shipment, order: order)
      bundle = create(:product, name: "Bundle")

      red_option = create(:option_value, presentation: "Red")
      blue_option = create(:option_value, presentation: "Blue")

      option_type = create(:option_type, presentation: "Color",
                                         name: "color",
                                         option_values: [
                                           red_option,
                                           blue_option
                                         ])

      variants = []
      selected_variants = {}
      parts.each do |part|
        product_properties = { can_be_part: true }
        if part[:variant_selection_deferred]
          product_properties[:option_types] = [option_type]
        end

        product = create(:product_in_stock, product_properties)

        assemblies_part_attributes = { assembly: bundle }.merge(part)

        if part[:variant_selection_deferred]
          create(:variant_in_stock, product: product,
                                    option_values: [red_option])
          variants << create(:variant_in_stock, product: product,
                                                option_values: [blue_option])
        else
          variants << product.master
        end

        assemblies_part_attributes[:part] = product.master
        create(:assemblies_part, assemblies_part_attributes)

        if part[:variant_selection_deferred]
          selected_variants = {
            "selected_variants" => {
              "#{bundle.assemblies_parts.last.id}" => "#{variants.last.id}"
            }
          }
        end
      end

      bundle.reload

      contents = Spree::OrderContents.new(order)
      line_item = contents.add_to_line_item_with_parts(
        bundle.master,
        line_item_quantity,
        selected_variants
      )
      line_item.reload

      [shipment, line_item, variants]
    end
  end
end
