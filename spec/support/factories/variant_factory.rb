require 'factory_girl'

FactoryGirl.define do
  factory :variant_in_stock, parent: :variant do
    transient do
      quantity_in_stock 10
    end

    after(:create) do |variant, evaluator|
      variant.stock_items.first.adjust_count_on_hand(
        evaluator.quantity_in_stock
      )
    end
  end
end
