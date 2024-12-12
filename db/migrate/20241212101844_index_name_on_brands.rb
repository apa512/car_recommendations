class IndexNameOnBrands < ActiveRecord::Migration[6.1]
  def change
    add_index :brands, :name, using: :gin, opclass: :gin_trgm_ops
  end
end
