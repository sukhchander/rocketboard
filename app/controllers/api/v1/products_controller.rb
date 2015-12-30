module Api
  module V1

    class ProductsController < Api::V1::ApiController

      def update
        product = Product.where(sku: product_details.sku).first

        if product.present?
          @product = product
        else
          @product = Product.create({
            sku: product_details.sku,
            name: product_details.description,
            description: product_details.description,
            unit_price: product_details.unit_price
          })
        end

        respond_with @product
      end

    private

      def product_details
        details = {sku: nil, description: nil, unit_price: nil}
        details.keys.each { |key| details[key] = params[key] if params.has_key? key }
        OpenStruct.new(details)
      end

    end

  end
end