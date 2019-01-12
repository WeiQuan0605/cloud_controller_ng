require 'actions/revision_create'

module VCAP::CloudController
  class AppStart
    class InvalidApp < StandardError; end

    class << self
      def start(app:, user_audit_info:, record_event: true)
        app.db.transaction do
          app.lock!
          process_attributes = { state: ProcessModel::STARTED }

          RevisionCreate.create(app) if app.can_create_revision? && app.desired_state != ProcessModel::STARTED

          app.update(desired_state: ProcessModel::STARTED)
          app.processes.each do |process|
            process.update(process_attributes)
          end

          record_audit_event(app, user_audit_info) if record_event
        end
      rescue Sequel::ValidationFailed => e
        raise InvalidApp.new(e.message)
      end

      def start_without_event(app)
        start(app: app, user_audit_info: nil, record_event: false)
      end

      private

      def record_audit_event(app, user_audit_info)
        Repositories::AppEventRepository.new.record_app_start(
          app,
          user_audit_info,
        )
      end
    end
  end
end
