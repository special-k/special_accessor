class Symbol
  def method_name?
    /[@"]/ !~ inspect
  end
end

class String
  def method_name?
    self.to_sym.method_name?
  end
end

class Module

  VALID_METHODS_ENDS = ['!','?']
  INVALID_ATTRIBUTE_NAME = 'invalid attribute name'

  def special_reader params
    raise ArgumentError, 'pass params by hash' unless params.is_a? Hash
    params.each{|field,v|
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" unless field.method_name?
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" if VALID_METHODS_ENDS.include? field[-1]
      set_default_for = :"__set_default_for_#{field}__"
      if v.is_a? Proc
        define_method set_default_for, -> {
          instance_variable_set("@#{ field }", v.call( self ) )
        }
      else
        define_method set_default_for, -> {
          instance_variable_set("@#{ field }", v )
        }
      end

      private set_default_for

      class_eval "def #{field}
        if @#{field}.nil?
          #{set_default_for}
        end
        @#{field}
      end"

    }
  end

  def special_writer *params
    if params.first.is_a?( Hash )
      attr_writer *params.first.keys
    else
      attr_writer *params
    end
  end

  def special_accessor params
    special_reader params
    special_writer params
  end

  def proxy_reader *params
    raise ArgumentError, 'proxy object not setted' unless params.last.is_a? Hash
    through = params.last[:through]
    raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{through}'" unless through.method_name?
    params[0..-2].each{|field|
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" unless field.method_name?
      class_eval "def #{field}; #{through}.#{field} end"
    }
  end

  def proxy_writer *params
    raise ArgumentError, 'proxy object not setted' unless params.last.is_a? Hash
    through = params.last[:through]
    raise ArgumentError, 'proxy object not setted' if through.nil?
    raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{through}'" unless through.method_name?
    raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{through}'" if VALID_METHODS_ENDS.include? through[-1]
    params[0..-2].each{|field|
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" unless field.method_name?
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" if VALID_METHODS_ENDS.include? field[-1]
      class_eval "def #{field}= v; #{through}.#{field} = v end"
    }
  end

  def proxy_accessor *params
    proxy_reader *params
    proxy_writer *params
  end

  def proxy_method *params
    raise ArgumentError, 'proxy object not setted' unless params.last.is_a? Hash
    through = params.last[:through]
    raise ArgumentError, 'proxy object not setted' if through.nil?
    raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{through}'" unless through.method_name?
    params[0..-2].each{|field|
      raise NameError, "#{ INVALID_ATTRIBUTE_NAME } `#{field}'" unless field.method_name?
      class_eval "def #{field} *args; #{through}.#{field} *args end"
    }
  end

  def set_accessor *params
    attr_reader *params
    set_writer *params
  end

  def set_writer *params
    params.each{|field|
      define_method "set_#{ field }", -> v { 
        instance_variable_set("@#{ field }", v )
      }
    }
  end

  def question_accessor *params

      t = {}
      params.each{|field|
        if field.is_a? Hash
          field.each{|k,v| t[k] = v }
        else
          t[field] = false
        end
      }

      t.each{|name,value|
        raise ArgumentError, "value can be only true or false but getted `#{value}" if value != true && value != false
        class_eval "def #{name}?
          if @is_#{name}.nil?
            @is_#{name} = #{value}
          end
          @is_#{name}
        end"

        class_eval "def #{name}!
          @is_#{name} = true
        end"

        class_eval "def unset_#{name}!
          @is_#{name} = false
        end"
      }

  end

end
