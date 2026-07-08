class Response
  HEADERS = [
    "StartDate", "EndDate", "Status", "IPAddress",
    "Progress", "Duration (in seconds)", "Finished", "RecordedDate",
    "ResponseId", "RecipientLastName", "RecipientFirstName",
    "RecipientEmail", "ExternalReference", "LocationLatitude",
    "LocationLongitude", "DistributionChannel", "UserLanguage",
    "Q13_1", "Q13_2", "Q13_3", "Q3", "Q4", "On Track or Not",
    "Q7_1", "Email", "FirstNameSSO",
    "LastNameSSO", "meeting", "FY", "Y", "ShortDate",
  ]

  def filled_out
    @data[17] # Q13_1
  end

  def met_supervisor
    @data[18] # Q13_2
  end

  def supervisor_feedback
    @data[19] # Q13_3
  end

  def why_no
    @data[21] # Q4
  end

  def supervisors_email
    @data[20] # Q3
  end

  def on_track_or_not
    @data[22] # On Track or Not
  end

  def email
    @data[24] # Email
  end

  def meeting
    @data[27] # meeting
  end

  def fy
    # in 25-26 there was a column (36, Y), sent from the IAP form to indicate the year
    # in 24-25 there was a self-reporting column (35, FY) to indicate the year
    # in 23-24 there was no column to indicate the year (thus this is the default)
    @data[29] || @data[28] || "23-24"
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
    ["No Response", nil, nil, nil, nil, nil, nil, ]
  end

  def report_columns
    [
      "Responded",
      filled_out,
      met_supervisor,
      supervisor_feedback,
      why_no,
      supervisors_email,
      on_track_or_not,
    ]
  end
end
