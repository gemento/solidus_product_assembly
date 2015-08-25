module Spree
  class AssignPartToBundleForm
    include ActiveModel::Validations

    validates :quantity, numericality: {greater_than: 0}

    attr_reader :product, :part_options

    def initialize(product, part_options)
      @product = product
      @part_options = part_options
    end

    def submit
      if valid?
        assemblies_part.update_attributes(attributes)
      end
    end

    private

    def attributes
      part_options.reject {|k, v| k.to_sym == :variant_id}
    end

    def given_id?
      part_options[:id].present?
    end

    def product_id
      product.id
    end

    def part_id
      variant.id
    end

    def variant
      Spree::Variant.find(part_options[:variant_id])
    end

    def variant_selection_deferred?
      part_options[:variant_selection_deferred]
    end

    def quantity
      part_options[:count].to_i
    end

    def assemblies_part
      @assemblies_part ||= begin
        if given_id?
          Spree::AssembliesPart.find(part_options[:id])
        else
          Spree::AssembliesPart.find_or_initialize_by(
            variant_selection_deferred: variant_selection_deferred?,
            assembly_id: product_id,
            part_id: part_id
          )
        end
      end
    end
  end
end
