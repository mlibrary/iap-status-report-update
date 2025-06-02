module QualtricsAPI
  class NewResponseExport < BaseModel
    values do
      attribute :export_progress_id, String
      attribute :survey_id, String
    end

    def update_status
      res = QualtricsAPI.connection(self).get("surveys/#{survey_id}/export-responses/#{export_progress_id}").body["result"]
      @export_progress = res["percentComplete"]
      @file_id = res["fileId"]
      @completed = true if @export_progress == 100.0 || 
      self
    end

    def status
      update_status unless completed?
      "#{@export_progress}%"
    end

    def percent_completed
      update_status unless completed?
      @export_progress
    end

    def in_progress?
      @completed == false
    end

    def completed?
      @completed == true
    end

    def file_url
      update_status unless completed?
      "#{QualtricsAPI.url}surveys/#{survey_id}/export-responses/#{@file_id}/file"
    end

    def get_file
      Faraday.new(url: file_url, headers: QualtricsAPI.connection.headers).get.body
    end

    def open(&block)
      #Kernel.open(@file_url, QualtricsAPI.connection(self).headers, &block)
    end
  end
end
