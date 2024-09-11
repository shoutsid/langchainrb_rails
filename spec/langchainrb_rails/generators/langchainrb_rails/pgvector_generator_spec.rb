require "spec_helper"

TMP_ROOT = Pathname.new(Dir.mktmpdir("tmp"))

RSpec.describe LangchainrbRails::Generators::PgvectorGenerator, type: :generator do
  destination TMP_ROOT
  arguments %w[--model=SupportArticle --llm=openai]

  before(:all) do
    prepare_destination
    model_file = TMP_ROOT.join("app/models/support_article.rb")
    gemfile = TMP_ROOT.join("Gemfile")
    write_file(model_file, "class SupportArticle < ApplicationRecord\nend")
    write_file(gemfile, "")
    run_generator
  end

  after(:all) { delete_directory(TMP_ROOT) }

  it "creates the initializer file" do
    assert_file "config/initializers/langchainrb_rails.rb"
  end

  it "creates the vector extension migration" do
    assert_migration "db/migrate/enable_vector_extension.rb"
  end

  it "adds the embedding column to the model" do
    assert_migration "db/migrate/add_vector_column_to_support_articles.rb" do |migration|
      assert_match(/add_column :support_articles, :embedding, :vector/, migration)
    end
  end

  it "adds the vectorsearch module to the model" do
    assert_file "app/models/support_article.rb" do |model|
      assert_match(/vectorsearch/, model)
      assert_match(/after_save :upsert_to_vectorsearch/, model)
    end
  end

  it "adds the necessary gems to the Gemfile" do
    assert_file "Gemfile" do |gemfile|
      assert_match(/gem "neighbor"/, gemfile)
      assert_match(/gem "ruby-openai"/, gemfile)
    end
  end
end
