# frozen_string_literal: true


require 'spec_helper'

module SupplejackApi
  module Stories
    describe ModerationsController do
      routes { SupplejackApi::Engine.routes }

      describe 'with an admin account' do
        before(:each) do
          @user = FactoryBot.create(:user, authentication_token: "abc123")
          allow(RecordSchema).to receive(:roles) { { admin: double(:admin, admin: true) } }
          allow(controller).to receive(:authenticate_user!) { true }
          allow(controller).to receive(:current_user) { @user }
        end

        describe '#index' do
          let!(:user_set) { FactoryBot.create(:user_set, name: "Dogs and cats", priority: 5) }

          before :each do
            allow(controller).to receive(:authenticate_admin!) { true }
            @normal_user = double(User, user_sets: []).as_null_object
            allow(User).to receive(:find_by_api_key).with("nonadminkey") { @normal_user }
          end

          it 'finds all public sets' do
            expect(UserSet).to receive(:all_public_sets) { [] }
            get :index, format: 'json'
          end

          it 'renders the public sets as JSON' do
            get :index, format: 'json'
            sets = JSON.parse(response.body)

            sets['sets'].each do |set|
              expect(set).to have_key 'id'
              expect(set).to have_key 'name'
              expect(set).to have_key 'count'
              expect(set).to have_key 'approved'
              expect(set).to have_key 'created_at'
              expect(set).to have_key 'updated_at'
            end
          end
        end
      end

      describe 'without an admin account' do
        it 'renders the appropriate message' do
          get :index, format: 'json'
          expect(response.body).to eq '{"errors":"Please provide a API Key"}'
        end
      end

    end
  end
end
