require 'spec_helper'
require 'actions/deployment_update'

module VCAP::CloudController
  RSpec.describe DeploymentUpdate do
    let(:user) { User.make }
    let(:user_email) { 'user@example.com' }
    let(:user_audit_info) { UserAuditInfo.new(user_email: 'user@example.com', user_guid: user.guid) }

    describe '#update' do
      let!(:deployment) { DeploymentModel.make }

      let!(:label) do
        VCAP::CloudController::DeploymentLabelModel.make(
          key_prefix: 'indiana.edu',
          key_name: 'state',
          value: 'Indiana',
          resource_guid: deployment.guid
        )
      end

      let!(:annotation) do
        VCAP::CloudController::DeploymentAnnotationModel.make(
          key: 'University',
          value: 'Toronto',
          resource_guid: deployment.guid
        )
      end

      let(:message) do
        VCAP::CloudController::DeploymentUpdateMessage.new({
          metadata: {
            labels: {
              freaky: 'wednesday',
              'indiana.edu/state' => nil,
            },
            annotations: {
              reason: 'add some more annotations',
            },
          },
        })
      end

      it 'update the deployment record' do
        expect(message).to be_valid
        updated_deployment = DeploymentUpdate.update(deployment, message)

        expect(updated_deployment.labels.first.key_name).to eq 'freaky'
        expect(updated_deployment.labels.first.value).to eq 'wednesday'
        expect(updated_deployment.labels.size).to eq 1
        expect(updated_deployment.annotations.size).to eq(2)
        expect(Hash[updated_deployment.annotations.map { |a| [a.key, a.value] }]).
          to eq({ 'University' => 'Toronto', 'reason' => 'add some more annotations' })
      end
    end
  end
end