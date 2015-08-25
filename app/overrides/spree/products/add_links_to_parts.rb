Deface::Override.new(
  virtual_path: "spree/products/_cart_form",
  name: "add_links_to_parts",
  insert_bottom: "[data-hook='inside_product_cart_form']",
  partial: "spree/products/show/parts"
)
