require 'factory_girl'

FactoryGirl.define do
  factory :part_line_item, class: "Spree::PartLineItem" do
    line_item
    variant
    quantity 1
  end
end
