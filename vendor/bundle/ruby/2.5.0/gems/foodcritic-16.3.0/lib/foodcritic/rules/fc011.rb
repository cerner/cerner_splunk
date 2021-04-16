rule "FC011", "Missing README in markdown format" do
  tags %w{readme supermarket}
  cookbook do |filename|
    unless File.exist?(File.join(filename, "README.md"))
      [file_match(File.join(filename, "README.md"))]
    end
  end
end
