module Rectify
  class Form
    include Virtus.model
    include ActiveModel::Validations

    attribute :id, Integer

    def self.from_params(params, additional_params = {})
      params_hash = hash_from(params)

      attribute_names = attribute_set.map(&:name)

      attributes = params_hash
        .fetch(mimicked_model_name, {})
        .merge(params_hash.slice(*attribute_names))
        .merge(additional_params)

      new(attributes)
    end

    def self.from_model(model)
      Rectify::BuildFormFromModel.new(self, model).build
    end

    def self.mimic(model_name)
      @model_name = model_name.to_s.underscore.to_sym
    end

    def self.mimicked_model_name
      @model_name || infer_model_name
    end

    def self.infer_model_name
      class_name = name.split("::").last
      return :form if class_name == "Form"

      class_name.chomp("Form").underscore.to_sym
    end

    def self.model_name
      ActiveModel::Name.new(self, nil, mimicked_model_name.to_s.camelize)
    end

    def self.hash_from(params)
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      params.with_indifferent_access
    end

    def persisted?
      id.present? && id.to_i > 0
    end

    def valid?(context = nil)
      [super, form_attributes_valid?, arrays_attributes_valid?].all?
    end

    def to_key
      [id]
    end

    def to_model
      self
    end

    def to_param
      id.to_s
    end

    def attributes
      super.except(:id)
    end

    def map_model(model)
      # Implement this in your form object for custom mapping from model to form
      # object as part of the `.from_model` call after matching attributes are
      # populated (optional).
    end

    private

    def form_attributes_valid?
      attributes
        .each_value
        .select { |f| f.respond_to?(:valid?) }
        .map(&:valid?)
        .all?
    end

    def arrays_attributes_valid?
      attributes
        .each_value
        .select { |a| a.is_a?(Array) }
        .flatten
        .select { |f| f.respond_to?(:valid?) }
        .map(&:valid?)
        .all?
    end
  end
end
