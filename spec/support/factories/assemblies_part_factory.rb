require 'factory_girl'

FactoryGirl.define do
  factory :assemblies_part, class: "Spree::AssembliesPart" do
    assembly { build(:product) }
    part { build(:variant) }
    count 1
    variant_selection_deferred false
  end
end
