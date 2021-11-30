# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::CatalogItemSerializer do
  let!(:product) { create(:simple_product ) }
  let!(:variant) { product.variants.first }

  subject { described_class.new(variant) }

  describe '#id' do
    let(:catalog_item_id) {
      [
        '/api/v0/dfc_provider',
        'enterprises',
        product.supplier_id,
        'catalog_items',
        variant.id
      ].join('/')
    }

    it 'returns the expected value' do
      expect(subject.id).to eq(catalog_item_id)
    end
  end

  describe '#references' do
    let(:supplied_product_id) {
      [
        '/api/v0/dfc_provider',
        'enterprises',
        product.supplier_id,
        'supplied_products',
        variant.id
      ].join('/')
    }

    it 'returns the expected value' do
      expect(subject.references).to eq(
        "@id" => supplied_product_id,
        "@type" => "@id"
      )
    end
  end
end
