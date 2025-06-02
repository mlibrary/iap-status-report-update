class Report
  def initialize(directory: , responses: , config: )
    @config = config
    @directory = directory
    @responses = responses
  end

  def write
    clean if @config["clean"]
    @config["fiscal_years"].each do |fy|
      @config["meetings"].each do |meeting_info|
        meeting = meeting_info["name"]
        code = meeting_info["code"]
        @directory.each_division do |department|
          file = "out/#{department}/#{fy || "23-24"}/IAP Status Report - #{department} - #{fy || "23-24"} - #{code} #{meeting}.csv"
          FileUtils.mkdir_p(File.dirname(file))
          CSV.open(file, "wb") do |csv|
            csv << [
              "Name", "Email", "Division (staff.lib)", "Department (staff.lib)", "Supervisor (staff.lib)",
              "FY", "Meeting",
              "Status", "Did you fill out your IAP for this meeting?", "Did you and your supervisor meet to discuss your IAP?",
              "Did your supervisor add feedback to your IAP?", "Why did you answer no on the other question(s)?", "Supervisor (qualtrics)", 
              "Division (qualtrics)", "Department (qualtrics)"
            ]
            department.members.each do |member|
              next if member.email == department.manager.email
              member_responses = @responses.get(email: member.email, fy: fy, meeting: meeting)
              member_columns = [ member.display_name, member.email, member.division, member.department, member.supervisor&.email ]
              config_columns = [ fy || "23-24", meeting ]
              response_columns = if member_responses.length < 1
                ["No Response", nil, nil, nil, nil, nil, nil, nil]
              else
                latest_response = member_responses.last
                [
                  "Responded",
                  latest_response.filled_out,
                  latest_response.met_supervisor,
                  latest_response.supervisor_feedback,
                  latest_response.why_no,
                  latest_response.supervisors_email,
                  latest_response.division,
                  latest_response.department
                ]
              end
              csv << member_columns + config_columns + response_columns
            end
            csv << []
            csv << ["Manager: #{department.manager.email}"]
            csv << ["Exported on: #{Time.now}"]
          end
        end
      end
    end
    sync if @config["sync"]
    self
  end

  def clean
    @session ||= GoogleDrive::Session.from_config(@config["credentials"])
    remote_root_name = @config["remote_root"]
    remote_root = @session.files(q: ["name = ?", remote_root_name]).find { |file| file.title == remote_root_name }
    remote_root.files.each { |file| file.delete(true) }
    self
  end

  def sync
    @session ||= GoogleDrive::Session.from_config(@config["credentials"])
    remote_root_name = @config["remote_root"]
    local_root_name = @config["local_root"]
    remote_root = @session.files(q: ["name = ?", remote_root_name]).find { |file| file.title == remote_root_name }
    files = Dir.glob("#{local_root_name}/**/*.csv")
    files.each do |file|
      file_name = File.basename(file, ".csv")
      relative_path = File.dirname(file[(local_root_name.length + 1)..file.length])
      current_folder = remote_root
      relative_path.split("/").each do |part|
        candidate = current_folder.files(q: ["name = ?", part]).find { |f| f.title == part }
        current_folder = candidate ? candidate : current_folder.create_subcollection(part)
      end
      candidate = current_folder.files(q: ["name = ?", file_name]).find { |f| f.title == file_name }
      if candidate
        candidate.update_from_file(file)
      else
        current_folder.upload_from_file(file, file_name)
      end
    end
    self
  end
end
