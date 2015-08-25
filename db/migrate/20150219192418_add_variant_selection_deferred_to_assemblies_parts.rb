class AddVariantSelectionDeferredToAssembliesParts < ActiveRecord::Migration
  def change
    add_column :spree_assemblies_parts, :variant_selection_deferred, :boolean
  end
end
