####################################################################### 
# 
# Decoration Token Forms:
#
# [link: click here]
#
# Decoration Tokens Allow Nesting:
# 
# [link: {count} {_messages}] 
# [link: {count||message}] 
# [link: {count||person, people}] 
# [link: {user.name}] 
#
####################################################################### 

class Tr8n::DecorationToken < Tr8n::Token
  
  def self.expression
    /(\[\w+:[^\]]+\])/
  end
  
  def language_rule
    nil
  end
  
  def value
    @value ||= begin
      parts = full_name.gsub(/[\]]/, '').split(':')
      vl = parts[1..-1].join(':')
      vl.strip
    end
  end
  
  # return as is
  def prepare_label_for_translator(label)
    label
  end

  # return only the internal part
  def prepare_label_for_suggestion(label)
    label.gsub(full_name, value)
  end
    
  def handle_default_decorations(lambda_token_name, lambda_token_value, token_values)
    unless Tr8n::Config.default_decorations[lambda_token_name]
      raise Tr8n::TokenException.new("Invalid decoration token value")
    end

    lambda_value = Tr8n::Config.default_decorations[lambda_token_name].clone

    params = [lambda_token_value]
    params += token_values[lambda_token_name.to_sym] if token_values[lambda_token_name.to_sym]
    
    params.each_with_index do |param, index|
      lambda_value.gsub!("{$#{index}}", param.to_s)
    end
    
    # clean all the rest of the {$num} params, if any
    param_index = params.size
    while lambda_value.index("{$#{param_index}}")
      lambda_value.gsub!("{$#{param_index}}", "")
      param_index += 1
    end
    
    lambda_value
  end  
  
  def substitute(label, values = {}, options = {}, language = Tr8n::Config.current_language)
    return if value.blank? 

    method = values[name_key]
    substitution_value = ""
    
    if method
      if method.is_a?(Proc)
        substitution_value = method.call(value)
      elsif method.is_a?(Array)
        substitution_value = handle_default_decorations(name, value, values)
      elsif method.is_a?(String)
        substitution_value = method.to_s.gsub("{$0}", value)
      else
        raise Tr8n::TokenException.new("Invalid decoration token value")
      end
    elsif Tr8n::Config.default_decorations[name]
      substitution_value = handle_default_decorations(name, value, values)
    else
      raise Tr8n::TokenException.new("Missing decoration token value")
    end
      
    label.gsub(full_name, substitution_value) 
  end
  
  def sanitized_name
    "[#{name}: ]"
  end
  
end
