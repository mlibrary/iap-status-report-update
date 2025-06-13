class Response
  HEADERS = [
    "StartDate", "EndDate", "Status", "IPAddress",
    "Progress", "Duration (in seconds)", "Finished", "RecordedDate",
    "ResponseId", "RecipientLastName", "RecipientFirstName",
    "RecipientEmail", "ExternalReference", "LocationLatitude",
    "LocationLongitude", "DistributionChannel", "UserLanguage",
    "Q13_1", "Q13_2", "Q13_3", "Q3", "Q10", "Q8", "Q9", "Q10", "Q11",
    "Q12", "Q13", "Q14", "Q4", "Q7_1", "Email", "FirstNameSSO",
    "LastNameSSO", "meeting", "FY", "ShortDate", "Y"
  ]

  def filled_out
    @data[17]
  end

  def met_supervisor
    @data[18]
  end

  def supervisor_feedback
    @data[19]
  end

  def why_no
    @data[29]
  end

  def supervisors_email
    @data[20]
  end

  def division
    @data[21]
  end

  def department
    @data[22..28].compact.first
  end

  def email
    @data[31]
  end

  def meeting
    @data[34]
  end

  def fy
    # in 25-26 there was a column (36, Y), sent from the IAP form to indicate the year
    # in 24-25 there was a self-reporting column (35, FY) to indicate the year
    # in 23-24 there was no column to indicate the year (thus this is the default)
    @data[36] || @data[35] || "23-24"
  end

  def initialize(row)
    @data = row
  end

  def complete?
    filled_out == "Yes" &&
      met_supervisor == "Yes" &&
      supervisor_feedback == "Yes"
  end

  def self.empty_report_columns
    ["No Response", nil, nil, nil, nil, nil, nil, nil]
  end

  def report_columns
    [
      "Responded",
      filled_out,
      met_supervisor,
      supervisor_feedback,
      why_no,
      supervisors_email,
      division,
      department
    ]
  end
end
