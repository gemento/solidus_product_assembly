module Spree
  LineItem.class_eval do
    scope :assemblies, -> { joins(product: :parts).uniq }

    has_many :part_line_items, dependent: :destroy

    def any_units_shipped?
      inventory_units.any? { |unit| unit.shipped? }
    end

    # The parts that apply to this particular LineItem. Usually `product#parts`,
    # but provided as a hook if you want to override and customize the parts for
    # a specific LineItem.
    def parts
      product.parts
    end

    # The number of the specified variant that make up this LineItem. By
    # default, calls `product#count_of`, but provided as a hook if you want to
    # override and customize the parts available for a specific LineItem. Note
    # that if you only customize whether a variant is included in the LineItem,
    # and don't customize the quantity of that part per LineItem, you shouldn't
    # need to override this method.
    def count_of(variant)
      product.count_of(variant)
    end

    def quantity_by_variant
      if product.assembly?
        if part_line_items.any?
          quantity_with_part_line_items(quantity)
        else
          quantity_without_part_line_items(quantity)
        end
      else
        { variant => quantity }
      end
    end

    private

    def update_inventory
      if (changed? || target_shipment.present?) &&
         order.has_checkout_step?("delivery")
        if product.assembly?
          OrderInventoryAssembly.new(self).verify(target_shipment)
        else
          OrderInventory.new(order, self).verify(target_shipment)
        end
      end
    end

    def quantity_with_part_line_items(quantity)
      part_line_items.each_with_object({}) do |ap, hash|
        hash[ap.variant] = ap.quantity * quantity
      end
    end

    def quantity_without_part_line_items(quantity)
      product.assemblies_parts.each_with_object({}) do |ap, hash|
        hash[ap.part] = ap.count * quantity
      end
    end
  end
end
