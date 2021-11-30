# frozen_string_literal: true

# Serializer used to render a DFC CatalogItem from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class CatalogItemSerializer < BaseSerializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :references, key: 'dfc:references'
    attribute :sku, key: 'dfc:sku'
    attribute :stock_limitation, key: 'dfc:stockLimitation'
    has_many :offered_through,
             serializer: DfcProvider::OfferSerializer,
             key: 'dfc:offeredThrough'

    def id
      api_v0_dfc_provider_enterprise_catalog_item_path(
        enterprise_id: object.product.supplier_id,
        id: object.id
      )
    end

    def type
      'dfc:CatalogItem'
    end

    def references
      {
        '@type' => '@id',
        '@id' => reference_id
      }
    end

    def stock_limitation; end

    def offered_through
      [object]
    end

    private

    def reference_id
      api_v0_dfc_provider_enterprise_supplied_product_path(
        enterprise_id: object.product.supplier_id,
        id: object.id
      )
    end
  end
end
