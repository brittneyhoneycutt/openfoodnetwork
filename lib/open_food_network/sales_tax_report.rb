module OpenFoodNetwork
  class SalesTaxReport
    include Spree::ReportsHelper
    attr_accessor :user, :params

    def initialize(user, params)
      @user = user
      @params = params
    end

    def header
      case params[:report_type]
      when "tax_types"
        ["Order number", "Date", "Items", "Items total (#{currency_symbol})", "Taxable Items Total (#{currency_symbol})",
          "Sales Tax (#{currency_symbol})", "Delivery Charge (#{currency_symbol})", "Tax on Delivery (#{currency_symbol})", "Tax on Fees (#{currency_symbol})",
          "Total Tax (#{currency_symbol})", "Customer", "Distributor"]
      else
        ["Order number", "Total excl. VAT"] +
          relevant_rates.map { |rate| "%s (%.1f%%)" % [rate.name, rate.amount.to_f * 100] } +
          ["Total VAT", "Total incl. VAT"]
      end
    end

    def search
      permissions = OpenFoodNetwork::Permissions.new(user)
      permissions.editable_orders.complete.not_state(:canceled).search(params[:q])
    end

    def orders
      search.result
    end

    def table
      case params[:report_type]
      when "tax_types"
        orders.map do |order|
          totals = totals_of order.line_items
          shipping_cost = shipping_cost_for order

          [order.number, order.created_at, totals[:items], totals[:items_total],
           totals[:taxable_total], totals[:sales_tax], shipping_cost, order.shipping_tax, order.enterprise_fee_tax, order.total_tax,
           order.bill_address.full_name, order.distributor.andand.name]
        end
      else
        orders.map do |order|
          [order.number, order.total - order.total_tax] +
            relevant_rates.map { |rate| order.tax_adjustment_totals.fetch(rate, 0) } +
            [order.total_tax, order.display_total]
        end
      end

    end


    private

    def relevant_rates
      queries = [ search.result.joins(:line_items => {:adjustments => :tax_rate}).select('spree_tax_rates.*').uniq,
                  search.result.joins(:adjustments => :tax_rate).select('spree_tax_rates.*').uniq ]
      queries.map do |query|
        ActiveRecord::Base.connection.select_all(query)
      end.sum.map do
        |tax_rate| Spree::TaxRate.new(tax_rate, without_protection: true)
      end
    end

    def totals_of(line_items)
      totals = {items: 0, items_total: 0.0, taxable_total: 0.0, sales_tax: 0.0}

      line_items.each do |line_item|
        totals[:items] += line_item.quantity
        totals[:items_total] += line_item.amount

        sales_tax = tax_included_in line_item

        if sales_tax > 0
          totals[:taxable_total] += line_item.amount
          totals[:sales_tax] += sales_tax
        end
      end

      totals.each_pair do |k, v|
        totals[k] = totals[k].round(2)
      end

      totals
    end

    def shipping_cost_for(order)
      shipping_cost = order.adjustments.find_by_label("Shipping").andand.amount
      shipping_cost = shipping_cost.nil? ? 0.0 : shipping_cost
    end

    def tax_included_in(line_item)
      line_item.adjustments.sum &:included_tax
    end

    def shipment_inc_vat
      Spree::Config.shipment_inc_vat
    end

    def shipping_tax_rate
      Spree::Config.shipping_tax_rate
    end
  end
end
