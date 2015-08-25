module Spree
  class PartLineItem < ActiveRecord::Base
    belongs_to :line_item
    belongs_to :variant, class_name: "Spree::Variant"
  end
end
