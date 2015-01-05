require 'spec_helper'
require './lib/migrator'

describe Migrator do
  before do
    @setting_file = YAML.load_file('spec/fixtures/settings/settings.yml')
  end
  it 'convert contentful model to contentful structure' do
    Migrator.new(@setting_file).run('--convert-content-model-to-json')
    contentful_structure = load_fixture('settings/contentful_structure_test')
    expect(contentful_structure.count).to eq 5
    expect(contentful_structure['Jobs']).to include(id: '4L1bg4WQ5aWQMiE82ouag', name: 'Jobs', displayField: 'title', description: nil)
    expect(contentful_structure['Jobs']['fields'].count).to eq 5
    expect(contentful_structure['Jobs']['fields']['Image']).to include(id: 'image', type: 'Asset', link: 'Link')
    expect(contentful_structure['Jobs']['fields']['Creator']).to include(id: 'creator', type: 'Entry', link: 'Link')
    expect(contentful_structure['Jobs']['fields']['Comments']).to include(id: 'comments', type: 'Array', link_type: 'Entry', link: 'Link')
  end

  it 'create content type json files from contentful structure' do
    Migrator.new(@setting_file).run('--create-contentful-model-from-json')
    expect(Dir.glob('spec/fixtures/import_files/collections/*').count).to eq 5
    content_types_files = %w(comment.json job_skills.json jobs.json profile.json user.json)
    Dir.glob('spec/fixtures/import_files/collections/*') do |directory_name|
      expect(content_types_files.include?(File.basename(directory_name))).to be true
    end
    comment = load_fixture('import_files/collections/comment')
    expect(comment).to include(id: '6H6pGAV1PUsuoAW26Iu48W', name: 'Comment', displayField: 'subject')
    expect(comment['fields'].count).to eq 2
    expect(comment['fields'].first).to include(id: 'subject', name: 'Subject', type: 'Text')

    job_skills = load_fixture('import_files/collections/job_skills')
    expect(job_skills).to include(id: '2soCP557HGKoOOK0SqmMOm', name: 'Job Skills', displayField: 'name')
    expect(job_skills['fields'].count).to eq 1
    expect(job_skills['fields'].first).to include(id: 'name', name: 'Name', type: 'Text')

    jobs = load_fixture('import_files/collections/jobs')
    expect(jobs).to include(id: '4L1bg4WQ5aWQMiE82ouag', name: 'Jobs', displayField: 'title')
    expect(jobs['fields'].count).to eq 6
    expect(jobs['fields'].last).to include(id: 'skills', name: 'Skills', type: 'Array', link_type: 'Entry', link: 'Link')

    profile = load_fixture('import_files/collections/profile')
    expect(profile).to include(id: '4WFZh4MwC4Mc0EQWAeOY8A', name: 'Profile', displayField: nil)
    expect(profile['fields'].count).to eq 2
    expect(profile['fields'].first).to include(id: 'nickname', name: 'Nickname', type: 'Text')

    user = load_fixture('import_files/collections/user')
    expect(user).to include(id: '1TVvxCqoRq0qUYAOQuOqys', name: 'User', displayField: 'first_name')
    expect(user['fields'].first).to include(id: 'first_name', name: 'First_name', type: 'Text')
  end

  it 'create content type json files from contentful structure' do
    vcr('import_content_types') do
      Migrator.new(@setting_file).run('--import-content-types', space_id: 'space_id')
    end
  end

  it 'prepare data to import - threads' do
    Migrator.new(@setting_file).run('--threads', thread: 2)
    expect(Dir.glob('spec/fixtures/import_files/threads/*').count).to eq 2
  end

  it 'import an entires to Contentful' do
    vcr('import_entries') do
      Migrator.new(@setting_file).run('--import')
    end
  end

  it 'import an assets to Contentful' do
    vcr('import_assets') do
      Migrator.new(@setting_file).run('--import-assets')
    end
  end

  it 'publish an entires' do
    vcr('publish_entries') do
      Migrator.new(@setting_file).run('--publish-entries')
    end
  end
  it 'publish an assets' do
    vcr('publish_asset') do
      Migrator.new(@setting_file).run('--publish-assets')
    end
  end


  context 'test credentials' do
    it 'when valid' do
      vcr('valid_credentials') do
        Migrator.new(@setting_file).run('--test-credentials')
      end
    end
    it 'when invalid' do
      vcr('invalid_credentials') do
        Migrator.new(@setting_file).run('--test-credentials')
      end
    end
  end

end
