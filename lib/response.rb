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
    @data[35]
  end

  def initialize(row)
    @data = row
  end
end
