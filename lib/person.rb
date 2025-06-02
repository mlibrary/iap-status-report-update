class Person
  attr_accessor :departments, :supervisor
  def initialize(data)
    @data = data
  end

  def uuid
    @data.dig("uuid", 0, "value")
  end

  def email
    @data.dig("field_user_email", 0, "value")
  end

  def display_name
    @data.dig("field_user_display_name", 0, "value")
  end

  def field_user_department
    @data["field_user_department"]
  end

  def department
    return @department if @department
    departments_parent_id = departments.map(&:parent_id)
    @department = departments.find { |dept| !departments_parent_id.include?(dept.department_id) }
  end

  def division
    @division ||= departments.find {|dept| dept.is_division?}
  end
end
