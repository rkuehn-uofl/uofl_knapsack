# frozen_string_literal: true
module Hyrax
  module FormatService
    def self.authority
      @authority ||= Qa::Authorities::Local.subauthority_for('format')
    end

    def self.authority=(val)
      @authority = val
    end

    def self.select_all_options
      authority.all.map do |element|
        [element[:label], element[:id]]
      end
    end

    def self.label(id)
      authority.find(id).fetch('term')
    end
  end
end
