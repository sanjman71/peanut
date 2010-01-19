# The standard vpim gem (the one that installs using gem install vpim) is not compatible with Ruby 1.9
# Instead we need to use this version: http://github.com/sam-github/vpim
#
require 'vpim/vcard'
require 'lib/user_initialize_helper'
include UserInitializeHelper

class VcardToPeanut
  
  attr_reader :cards

  def initialize(filename)
    @cards = Vpim::Vcard.decode(open(filename))
  end
  
  def process(company, password, category = nil, display_results = true, save_results = false)
    if save_results && company.blank?
      puts "To save your results you must specify a company"
      return
    end
    if display_results
      puts "Total of #{@cards.size} contacts"
    end
    @cards.each_with_index do |card, index|
      if category.blank? || (card[:categories] == category)
        user_fields = {}
        user_fields[:name] = card[:fn]
        user_fields[:password] = user_fields[:password_confirmation] = password
        user_fields[:phone_numbers_attributes] = []
        user_fields[:email_addresses_attributes] = []
        card.each do |field|
          if field.name == 'TEL'
            # Possibilities for type are "HOME", "WORK", "CELL"
            if field.pvalues('TYPE').blank? || field.pvalues('TYPE').include?('CELL')
              type = 'Mobile'
            elsif field.pvalues('TYPE').include?('WORK')
              type = 'Work'
            elsif field.pvalues('TYPE').include?('HOME')
              type = 'Home'
            else
              type = 'Other'
            end
            if !field.pvalues('TYPE').blank? && field.pvalues('TYPE').include?('pref')
              priority = PhoneNumber::PRIORITY_HIGHEST
            else
              priority = PhoneNumber::PRIORITY_MEDIUM
            end
            user_fields[:phone_numbers_attributes] << {:address => field.value, :name => type, :priority => priority}
          elsif (field.name == 'EMAIL')
            if !field.pvalues('TYPE').blank? && field.pvalues('TYPE').include?('pref')
              priority = EmailAddress::PRIORITY_HIGHEST
            else
              priority = EmailAddress::PRIORITY_MEDIUM
            end
            user_fields[:email_addresses_attributes] << {:address => field.value, :priority => priority}
          end
        end
        u = User.new(user_fields)
        if u.valid?
          if display_results
            puts "#{index} Saving #{u.name}: #{u.phone_numbers.sort{|a,b| a.priority <=> b.priority}.map{|p| p.name + ":" + p.address}.join(', ') }; #{u.email_addresses.sort{|a,b| a.priority <=> b.priority}.map{|e| e.address}.join(', ') }"
          end
          if save_results
            u.save
            # Add the user as a customer of the company
            u.grant_role('company customer', company)
          end
        else
          puts "#{index} Couldn't save record for #{user_fields[:name]}: #{u.errors.full_messages}"
        end
      else
        puts "#{index} #{card[:fn]} is not in the chosen category"
      end
    end
    []
  end
  
end
