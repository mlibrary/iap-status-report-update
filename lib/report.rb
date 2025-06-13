class Report
  DS_WHITE = {red: 1.0, green: 1.0, blue: 1.0 }
  DS_NEUTRAL_300 = { red: 0x63 / 255.0, green: 0x73 / 255.0, blue: 0x81 / 255.0 }
  DS_PINK_300 = { red: 0xEC/255.0, green: 0x69/255.0, blue: 0x69/255.0 }
  DS_MAIZE_300  = { red: 1.0, green: 0xDA / 255.0, blue: 0x50 / 255.0 }
  DS_MAIZE_200 = { red: 1.0, green: 0xEA / 255.0, blue: 0x9B / 255.0 }
  DS_PINK_200 = { red: 0xF2 / 255.0, green: 0x9D / 255.0, blue: 0x9D / 255.0 }
  DS_NEUTRAL_200 = { red: 0x7A / 255.0, green: 0x96 / 255.0, blue: 0xA1 / 255.0}


  SUBMITTED_SUMMARY = "Submitted the Qualtrics form: %3.2f%%"
  QUESTIONS_SUMMARY = "Answered 'Yes' to the primary questions on the Qualtrics form: %3.2f%%"

  def initialize(directory: , responses: , config: )
    @config = config
    @directory = directory
    @responses = responses
  end

  def file_name(department: nil, supervisor: nil, full: false, fy:, code:, meeting:)
    if full
      "out/Full/#{fy}/IAP Status Report - Full - #{fy} - #{code} #{meeting}.csv"
    elsif department
      "out/By Department/IAP Status Reports - #{department}/#{fy}/IAP Status Report - #{department} - #{fy} - #{code} #{meeting}.csv"
    elsif supervisor
      "out/By Supervisor/IAP Status Reports - #{supervisor}/#{fy}/IAP Status Report - #{supervisor} - #{fy} - #{code} #{meeting}.csv"
    else
      raise "Must be one of full, department or supervisor."
    end
  end

  def write
    clean if @config["clean"]
    header = [
      "First Name", "Last Name", "Division (staff.lib)", "Department (staff.lib)", "Supervisor (staff.lib)",
      "FY", "Meeting",
      "Status", "Did you fill out your IAP for this meeting?", "Did you and your supervisor meet to discuss your IAP?",
      "Did your supervisor add feedback to your IAP?", "Why did you answer no on the other question(s)?", "Supervisor (qualtrics)",
      "Division (qualtrics)", "Department (qualtrics)"
    ]
    @config["fiscal_years"].each do |fy|
      @config["meetings"].each do |meeting_info|
        meeting = meeting_info["name"]
        config_columns = [ fy, meeting ]
        code = meeting_info["code"]
        full_file = file_name(full: true, fy: fy, code: code, meeting: meeting)
        FileUtils.mkdir_p(File.dirname(full_file))
        CSV.open(full_file, "wb") do |full_csv|
          full_csv << header
          full_length = 0
          full_completed = 0
          full_responded = 0

          @directory.each_supervisor do |supervisor|
            file = file_name(supervisor: supervisor.display_name, fy: fy, code: code, meeting: meeting)
            FileUtils.mkdir_p(File.dirname(file))
            CSV.open(file, "wb") do |csv|
              csv << header
              completed = 0
              responded = 0
              direct_reports_length = 0
              direct_reports = @directory.direct_reports_for(supervisor)
              direct_reports.each do |employee|
                next if @config["exclude"].include?(employee.email)
                direct_reports_length += 1
                employee_responses = @responses.get(email: employee.email, fy: fy, meeting: meeting)
                employee_columns = employee.report_columns
                response_columns = if employee_responses.length < 1
                  Response.empty_report_columns
                else
                  latest_response = employee_responses.last
                  responded += 1
                  if latest_response.complete?
                    completed += 1
                  end
                  latest_response.report_columns
                end
                csv << employee_columns + config_columns + response_columns
              end
              csv << []
              csv << ["Manager: #{supervisor.display_name}"]
              csv << ["Exported on: #{Time.now}"]
              if direct_reports_length > 0
                csv << [(SUBMITTED_SUMMARY % [100.0 * responded / direct_reports_length ])]
                csv << [(QUESTIONS_SUMMARY % [100.0 * completed / direct_reports_length ])]
              end
            end
          end

          @directory.each_division do |department|
            file = file_name(department: department, fy: fy, code: code, meeting: meeting)
            FileUtils.mkdir_p(File.dirname(file))
            CSV.open(file, "wb") do |csv|
              csv << header
              completed = 0
              responded = 0
              department_members_length = 0
              department.members.each do |member|
                next if member.email == department.manager.email
                next if @config["exclude"].include?(member.email)
                full_length += 1
                department_members_length += 1
                member_responses = @responses.get(email: member.email, fy: fy, meeting: meeting)
                member_columns = member.report_columns
                response_columns = if member_responses.length < 1
                  Response.empty_report_columns
                else
                  latest_response = member_responses.last
                  responded += 1
                  full_responded += 1
                  if latest_response.complete?
                    completed += 1
                    full_completed += 1
                  end
                  latest_response.report_columns
                end
                csv << member_columns + config_columns + response_columns
                full_csv << member_columns + config_columns + response_columns
              end
              csv << []
              csv << ["Manager: #{department.manager.display_name}"]
              csv << ["Exported on: #{Time.now}"]
              if department_members_length > 0
                csv << [(SUBMITTED_SUMMARY % [100.0 * responded / department_members_length ])]
                csv << [(QUESTIONS_SUMMARY % [100.0 * completed / department_members_length ])]
              end
            end
          end
          full_csv << []
          full_csv << ["Exported on: #{Time.now}"]
          if full_length > 0
            full_csv << [(SUBMITTED_SUMMARY % [100.0 * full_responded / full_length ])]
            full_csv << [(QUESTIONS_SUMMARY % [100.0 * full_completed / full_length ])]
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

  def request_muli_font(sheet_id)
    {
      repeat_cell: {
        range: {
          sheet_id: sheet_id,
        },
        cell: {
          user_entered_format: {
            text_format:  {
               font_family: "Muli"
            },
          }
        },
        fields: "userEnteredFormat(text_format)",
      }
    }
  end

  def request_header_format(sheet_id)
    {
      repeat_cell: {
        range: {
          sheet_id: sheet_id,
          start_row_index: 0,
          end_row_index: 1
        },
        cell: {
          user_entered_format: {
            background_color: DS_NEUTRAL_300,
            text_format:  {
               font_family: "Muli",
               foreground_color: DS_WHITE,
               font_size: 12,
               bold: true
            },
            padding: {
              top: 6,
              right: 8,
              bottom: 6,
              left: 8
            }
          }
        },
        fields: "userEnteredFormat(background_color,text_format,padding)",
      }
    }
  end

  def request_frozen_header(sheet_id)
    {
      update_sheet_properties: {
        properties: {
          sheet_id: sheet_id ,
          grid_properties: {
            frozen_row_count: 1
          }
        },
        fields: "grid_properties.frozen_row_count"
      }
    }
  end

  def request_no_response_highlighting(sheet_id)
    {
      add_conditional_format_rule: {
        rule: {
          ranges: [
            {
              sheet_id: sheet_id,
              start_row_index: 1,
              start_column_index: 0,
            }
          ],
          boolean_rule: {
            condition: {
              type: "CUSTOM_FORMULA",
              values: [{
                user_entered_value: '=EQ($H2,"No Response")'
              }]
            },
            format:  {
              background_color: DS_PINK_200
            }
          }
        },
        index: 0
      }
    }
  end

  def request_answered_no_highlighting(sheet_id)
    {
      add_conditional_format_rule: {
        rule: {
          ranges: [{
            sheet_id: sheet_id,
            start_row_index: 1,
            start_column_index: 0,
          }],
          boolean_rule: {
            condition: {
              type: "CUSTOM_FORMULA",
              values:[{
                user_entered_value: '=OR(EQ($I2, "No"), EQ($J2, "No"), EQ($K2, "No"))'
              }]
            },
            format: {
              background_color: DS_MAIZE_200
            }
          }
        },
        index: 1
      }
    }
  end

  def batch_update_style_requests(sheet_id)
    [
      request_muli_font(sheet_id),
      request_header_format(sheet_id),
      request_frozen_header(sheet_id),
      request_no_response_highlighting(sheet_id),
      request_answered_no_highlighting(sheet_id),
    ]
  end

  def style(sheet)
    sheet.batch_update(batch_update_style_requests(sheet.worksheets.first.gid.to_i))
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
        candidate = current_folder.upload_from_file(file, file_name)
      end
      style(candidate)
    end
    self
  end
end
