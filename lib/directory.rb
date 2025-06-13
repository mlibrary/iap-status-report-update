class Directory
  def initialize(config)
    @departments = {}
    @people = {}

    JSON.parse(if config["people"].start_with?("https://")
      Faraday.new(config["people"]).get.body
    else
      File.read(config["people"])
    end).each do |person_data|
      person = Person.new(person_data)
      @people[person.email] = person
      @people[person.uuid] = person
      person.departments = person.field_user_department.map do |department|
        (@departments[department["target_uuid"]] ||=
          Department.new(department.merge("fetch" => config["department_base_url"] + department["target_uuid"]))).tap do |dept|
            dept.members << person
        end
      end
    end

    JSON.parse(if config["supervisors"].start_with?("https://")
      Faraday.new(config["supervisors"]).get.body
    else
      File.read(config["supervisors"])
    end).each do |supervisor_map|
      @people[supervisor_map["uniqname"] + "@umich.edu"].supervisor = @people[supervisor_map["supervisor"] + "@umich.edu"]
    end

    head_department_id = nil
    @departments.values.each do |department|
      department.manager = @people[department.department_head_uuid]
      department.parent = @departments.values.find { |dept| dept.department_id == department.parent_id }
      if department.parent.nil?
        head_department_id = department.department_id
        department.is_division = true
      end
    end

    @departments.values.select do |department|
      department.parent_id == head_department_id
    end.each do |department|
      department.is_division = true
    end
  end

  def each_division
    @departments.values.select(&:is_division?).each { |item| yield item }
  end

  def each_department
    @departments.values.each { |item| yield item }
  end

  def each_person
    @people.values.uniq.each { |item| yield item }
  end

  def each_supervisor
    @people.values.map(&:supervisor).compact.uniq.each { |item| yield item }
  end

  def direct_reports_for(supervisor)
    @people.values.select { |person| person.supervisor == supervisor }.uniq
  end
end
