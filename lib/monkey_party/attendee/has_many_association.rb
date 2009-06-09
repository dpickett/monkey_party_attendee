module MonkeyParty
  module Attendee
    class HasManyAssociation
      attr_reader :name, :limit, :include, :expression
      def initialize(name, options = {})
        @name = name
        @limit = options[:limit] || 5
        @include = options[:include]
        @expression = options[:expression]
      end


      def to_merge_field_for(obj)
        aliased_field = "#{@name}_expression"

        #ugly dependency on a derived column plugin
        collection = obj.send(@name).find(:all, 
          :limit => @limit, 
          :select => "#{@expression} as #{aliased_field}",
          :include => @include)

        {
          @name.to_sym => collection.collect{|i| i["#{aliased_field}"]}.join(", ")
        }
      end
    end
  end
end
