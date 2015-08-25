module Spree
  OrderContents.class_eval do
    def add_to_line_item_with_parts(variant, quantity, options = {})
      add_to_line_item_without_parts(variant, quantity, options).
        tap do |line_item|
        populate_part_line_items(
          line_item,
          variant.product.assemblies_parts,
          options["selected_variants"]
        )
      end
    end
    alias_method_chain :add_to_line_item, :parts

    private

    def populate_part_line_items(line_item, parts, selected_variants)
      parts.each do |part|
        line_item.part_line_items.create!(
          line_item: line_item,
          variant_id: variant_id_for(part, selected_variants),
          quantity: part.count
        )
      end
    end

    def variant_id_for(part, selected_variants)
      if part.variant_selection_deferred?
        selected_variants[part.id.to_s]
      else
        part.part.id
      end
    end
  end
end
