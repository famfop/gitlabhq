# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin issues labels', feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let!(:bug_label) { Label.create!(title: 'bug', template: true) }
  let!(:feature_label) { Label.create!(title: 'feature', template: true) }

  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'list' do
    before do
      visit admin_labels_path
    end

    it 'renders labels list' do
      page.within '.manage-labels-list' do
        expect(page).to have_content('bug')
        expect(page).to have_content('feature')
      end
    end

    it 'deletes label' do
      page.within "#label_#{bug_label.id}" do
        click_link 'Delete'
      end

      page.within '.manage-labels-list' do
        expect(page).not_to have_content('bug')
      end
    end

    it 'deletes all labels', :js do
      page.all('.labels .label-actions-list').each do |label|
        label.click
        accept_gl_confirm(button_text: 'Delete label') do
          click_link 'Delete'
        end
        wait_for_requests
      end

      wait_for_requests

      expect(page).to have_content("Define your default set of project labels")
      expect(page).not_to have_content('bug')
      expect(page).not_to have_content('feature_label')

      page.within '.js-admin-labels-count' do
        expect(page).to have_content('0')
      end
    end
  end

  describe 'create' do
    before do
      visit new_admin_label_path
    end

    it 'creates new label' do
      fill_in 'Title', with: 'support'
      fill_in 'Background color', with: '#F95610'
      click_button 'Create label'

      page.within '.manage-labels-list' do
        expect(page).to have_content('support')
      end
    end

    it 'does not creates label with invalid color' do
      fill_in 'Title', with: 'support'
      fill_in 'Background color', with: '#12'
      click_button 'Create label'

      page.within '.label-form' do
        expect(page).to have_content('Color must be a valid color code')
      end
    end

    it 'does not creates label if label already exists' do
      fill_in 'Title', with: 'bug'
      fill_in 'Background color', with: '#F95610'
      click_button 'Create label'

      page.within '.label-form' do
        expect(page).to have_content 'Title has already been taken'
      end
    end
  end

  describe 'edit' do
    it 'changes bug label' do
      visit edit_admin_label_path(bug_label)

      fill_in 'Title', with: 'fix'
      fill_in 'Background color', with: '#F15610'
      click_button 'Save changes'

      page.within '.manage-labels-list' do
        expect(page).to have_content('fix')
      end
    end

    it 'allows user to delete label', :js do
      visit edit_admin_label_path(bug_label)

      click_button 'Delete'

      within_modal do
        expect(page).to have_content("#{bug_label.title} will be permanently deleted. This cannot be undone.")

        click_link 'Delete label'
      end

      expect(page).to have_content('Label was removed')
    end
  end
end
