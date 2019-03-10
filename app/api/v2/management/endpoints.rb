# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Endpoints < Grape::API
        desc 'Creates member accounts for each currency. It creates the member if not exists.' do
          @settings[:scope] = :read_accounts
        end
        params do
          requires :uid,      type: String, desc: 'The member UID.'
          requires :email,    type: String, desc: 'The member e-mail'
          requires :role,     type: String, desc: 'The member role'
          requires :state,    type: String, desc: 'The member state.'
          requires :level,    type: Integer, desc: 'The level of authentication.'
        end
        post '/create_accounts' do
          begin
            member = Member.from_payload(params)
              # Handle race conditions when creating member record.
              # We do not handle race condition for update operations.
              # http://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by
          rescue ActiveRecord::RecordNotUnique
            retry
          end
          Currency.find_each do |currency|
            next if member.accounts.where(currency: currency).exists?

            member.accounts.create!(currency: currency)
          end
          status 200
          {status: "ok"}
        end

        desc 'Returns deposit address for account you want to deposit to. ' \
         'The address may be blank because address generation process is still in progress. ' \
         'If this case you should try again later.' do
          @settings[:scope] = :read_deposits
        end
        params do
          requires :uid,      type: String, desc: 'The user id.'
          requires :currency, type: String, values: -> { Currency.coins.enabled.codes(bothcase: true) }, desc: 'The account you want to deposit to.'
          given :currency do
            optional :address_format, type: String, values: -> { %w[legacy cash] }, validate_currency_address_format: true, desc: 'Address format legacy/cash'
          end
        end
        post '/deposit_address' do
          status 200
            member = Member.find_by_uid(params[:uid])
            if member
              account = member.get_account(params[:currency])

              body account.payment_address.yield_self do |pa|
                { currency: params[:currency], address: params[:address_format] ? pa.format_address(params[:address_format]) : pa.address }
              end
            else
              {error: "Member not found. Please inform a valid uid."}
            end
        end
      end
    end
  end
end
