module Spree
  class EmailTemplate < Spree::Base
    belongs_to :store, class_name: 'Spree::Store', optional: true
    validates_uniqueness_of :name
    validate :validate_from_ses
    after_destroy :destroy_from_ses
    # before_commit -> { self.client_id = self.store.client_id }, if: -> { name.eql?('scheduled_report_recipients') }

    def validate_from_ses
      aws_client = Aws::SES::Client.new()
      aws_template = {
        template: {
          template_name: name,
          subject_part: subject,
          html_part: html
        }
      }

      begin
        aws_client.get_template(template_name: name)
        templated = true
      rescue => e
        templated = false if e.message.include?("Template #{name} does not exist")
      end

      begin
        templated ? aws_client.update_template(aws_template) : aws_client.create_template(aws_template)
      rescue StandardError => e
        errors.add :errors, e  and return
      end
    end

    def destroy_from_ses
      aws_client = Aws::SES::Client.new()
      aws_template = {
        template_name: name
      }

      begin
        aws_client.delete_template(aws_template)
      rescue StandardError => e
        errors.add :errors, e  and return
      end
    end

  end
end
