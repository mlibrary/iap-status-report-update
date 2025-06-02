class Department
  CACHE = {}
  attr_reader :members
  attr_accessor :manager, :parent
  def initialize(data)
    @data = data
    @full_data = (CACHE[data["target_uuid"]] ||= JSON.parse(Faraday.new(data["fetch"]).get.body))
    #@full_data = JSON.parse(Faraday.new(data["fetch"]).get.body)
    @members = []
    @is_division = nil
  end

  def is_division=(value)
    @is_division = value
  end

  def is_division?
    @is_division
  end

  def department_head_uuid
    @full_data.dig("data", "relationships", "field_department_head", "data", 0, "id")
  end

  def department_id
    @full_data.dig("data", "attributes", "field_departmentid")
  end

  def parent_id
    @full_data.dig("data", "attributes", "field_parent_department_id")
  end

  def to_s
    @full_data.dig("data", "attributes", "title")
  end
end
