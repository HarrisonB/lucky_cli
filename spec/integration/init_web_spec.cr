require "../spec_helper"

include ShouldRunSuccessfully

Spec.before_each do
  FileUtils.rm_rf("test-project")
end

describe "Initializing a new web project" do
  it "creates a full web app successfully" do
    puts "Web app: Running integration spec. This might take awhile...".colorize(:yellow)
    should_run_successfully "crystal src/lucky.cr init test-project"
    FileUtils.cp("spec/support/cat.gif", "test-project/public/assets/images/")
    compile_and_run_specs_on_test_project
    File.read("test-project/.travis.yml").should contain "postgresql"
    File.read("test-project/public/mix-manifest.json").should contain "images/cat.gif"
  end

  it "creates a full web app with generator" do
    puts "Web app generators: Running integration spec. This might take awhile...".colorize(:yellow)
    should_run_successfully "crystal src/lucky.cr init test-project"

    FileUtils.cd "test-project" do
      should_run_successfully "shards install"
      should_run_successfully "lucky gen.action.api Api::Users::Show"
      should_run_successfully "lucky gen.action.browser Users::Show"
      should_run_successfully "lucky gen.migration CreateThings"
      should_run_successfully "lucky gen.model User"
      should_run_successfully "lucky gen.page Users::IndexPage"
      should_run_successfully "lucky gen.component Users::Header"
      should_run_successfully "lucky gen.resource.browser Comment title:String"

      File.read("src/actions/comments/index.cr").should contain "Comments::Index"
      File.read("src/actions/api/users/show.cr").should_not be_nil
      File.read("src/actions/users/show.cr").should_not be_nil
      File.read("src/pages/users/index_page.cr").should_not be_nil
      File.read("src/components/users/header.cr").should contain "Users::Header < BaseComponent"
      should_run_successfully "crystal build src/server.cr"
    end
  end

  it "creates an api only web app successfully" do
    puts "Api only: Running integration spec. This might take awhile...".colorize(:yellow)
    should_run_successfully "crystal src/lucky.cr init test-project -- --api"
    compile_and_run_specs_on_test_project
  end

  it "creates an api only app without auth" do
    puts "Api only without auth: Running integration spec. This might take awhile...".colorize(:yellow)
    should_run_successfully "crystal src/lucky.cr init test-project -- --api --no-auth"
    compile_and_run_specs_on_test_project
  end

  it "creates a full app without auth" do
    puts "Web app without auth: Running integration spec. This might take awhile...".colorize(:yellow)
    should_run_successfully "crystal src/lucky.cr init test-project -- --no-auth"
    compile_and_run_specs_on_test_project
  end

  it "does not create project if directory with same name already exist" do
    FileUtils.mkdir "test-project"
    output = IO::Memory.new
    Process.run(
      "crystal src/lucky.cr init test-project",
      output: output,
      shell: true
    )
    message = "Folder named test-project already exists, please use a different name"
    output.to_s.strip.should contain(message)
  end
end

private def compile_and_run_specs_on_test_project
  FileUtils.cd "test-project" do
    should_run_successfully "bin/setup"
    should_run_successfully "crystal tool format --check spec src"
    should_run_successfully "crystal build src/server.cr"
    should_run_successfully "crystal build src/test_project.cr"
    should_run_successfully "crystal src/app.cr"
    should_run_successfully "crystal spec"
  end
end
