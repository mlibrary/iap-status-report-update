module QualtricsAPI
  module Services
    class NewResponseExportService < QualtricsAPI::BaseModel
      values do
        attribute :format, String, :default => 'csv'
        attribute :survey_id, String
        attribute :last_response_id, String
        attribute :start_date, String
        attribute :end_date, String
        attribute :limit, String
        attribute :included_question_ids, String
        attribute :use_labels, Boolean, :default => false
        attribute :decimal_separator, String, :default => '.'
        attribute :seen_unanswered_recode, String
        attribute :use_local_time, Boolean, :default => false

        attribute :id, String
      end
      
      attr_reader :result

      def start
        response = QualtricsAPI.connection(self).post("surveys/#{survey_id}/export-responses", export_params)
        export_id = response.body["result"]["progressId"]
        @result = NewResponseExport.new(export_progress_id: export_id, survey_id: survey_id)
      end

      def export_configurations
        {
          format: format,
          last_response_id: last_response_id,
          start_date: start_date,
          end_date: end_date,
          limit: limit,
          included_question_ids: included_question_ids,
          use_labels: use_labels,
          seen_unanswered_recode: seen_unanswered_recode,
        }
      end

      private

      def param_mappings
        {
          format: "format",
          last_response_id: "lastResponseId",
          start_date: "startDate",
          end_date: "endDate",
          limit: "limit",
          included_question_ids: "includedQuestionIds",
          use_labels: "useLabels",
          seen_unanswered_recode: "seenUnansweredRecode",
        }
      end

      def export_params
        export_configurations.map do |config_key, value|
          [param_mappings[config_key], value] unless value.nil? || value.to_s.empty?
        end.compact.to_h
      end
    end
  end
end
