class Responses

  def check_header!
    header = @csv_data.first
    return self if header[17] == "Q13_1" &&
      header[18] == "Q13_2" &&
      header[19] == "Q13_3" &&
      header[20] == "Q3" &&
      header[21] == "Q10" &&
      header[22] == "Q8" &&
      header[23] == "Q9" &&
      header[24] == "Q10" &&
      header[25] == "Q11" &&
      header[26] == "Q12" &&
      header[27] == "Q13" &&
      header[28] == "Q14" &&
      header[29] == "Q4" &&
      header[31] == "Email" &&
      header[34] == "meeting" &&
      header[35] == "FY"
      header[36] == "Y"

    puts "CSV DATA has an inconsistent header."
    raise "CSV DATA has an inconsistent header."
  end

  def initialize(config)
    QualtricsAPI.configure do |qualtrics|
      qualtrics.api_token = config["api_token"]
      qualtrics.data_center_id = config["data_center_id"]
    end

    survey = QualtricsAPI.surveys.find(config.dig("survey_id"))
    export_service = survey.new_export_responses(use_labels: true)
    export = export_service.start
    sleep 5
    export.status
    while !export.completed? do
      puts "Waiting on export.  #{export.percent_completed}%"
      sleep 10
      export.update_status
    end
    file = export.get_file
    zip = Zip::File.open_buffer(file)
    csv_file = zip.entries.first.get_input_stream.read
    @csv_data = CSV.parse(csv_file)
    check_header!
    @csv_data.delete(0)
    @csv_data.delete(0)
    @csv_data.delete(0)
    @people = {}
    @csv_data.each do |row|
      response = Response.new(row)
      @people[response.email] ||= {}
      @people[response.email][response.fy] ||= {}
      @people[response.email][response.fy][response.meeting] ||= []
      @people[response.email][response.fy][response.meeting] << response
    end
  end

  def get(email:, fy:, meeting:)
    @people.dig(email, fy, meeting) || []
  end

  def each(fy:  nil, meeting: nil, &block)
    if meeting.nil? && fy.nil?
      @csv_data.each do |row|
        yield row
      end
    else
      @csv_data.select do |row|
        row["FY"] == fy && (meeting.nil? || meeting == row["meeting"])
      end.each  do |row|
        yield row
      end
    end
  end
end
