# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Course.

course = Course.main
course.update_attributes! :number => '1.337', :title => 'Intro to Pwnage',
                          :has_recitations => false, :has_surveys => false,
                          :has_teams => false
prereq1 = Prerequisite.new :prerequisite_number => '6.01',
    :waiver_question => 'Programming experience'
prereq1.course = course
prereq1.save!

prereq2 = Prerequisite.new :prerequisite_number => '6.042',
    :waiver_question => 'Math experience'
prereq2.course = course
prereq2.save!

# Staff.

admin = User.create :email => 'costan@mit.edu', :password => 'mit',
    :password_confirmation => 'mit', :active => true, :admin => true
admin.email_credential.key = '1'
admin.admin = true
admin.save!

admin_profile = Profile.create! :user => admin, :name => 'Victor Costan',
    :nickname => 'Victor', :university => 'MIT', :department => 'EECS',
    :year => 'G', :athena_username => 'costan', :about_me => "I'm the boss"

# Students.

names = File.read('db/seeds/names.txt').split("\n").
    map { |line| line.split('.', 2).last.strip }
depts = File.read('db/seeds/depts.txt').split("\n").
    map { |line| line.split('(', 2).first.strip }

users = []
names.each_with_index do |name, i|
  first_name = name.split(' ').first
  short_name = (first_name[0, 1] + name.split(' ').last).downcase
  user = User.create :email => short_name + '@mit.edu',  :password => 'mit',
                     :password_confirmation => 'mit'
  user.email_credential.key = '1'
  user.save!
  users << user
  
  Profile.create! :user => user, :name => name,
      :nickname => first_name, :university => 'MIT',
      :department => depts[i % depts.length], :year => (1 + (i % 4)).to_s,
      :athena_username => short_name, :about_me => "Test subject #{i + 1}"

  registration = Registration.create! :user => user, :course => course,
      :dropped => false, :for_credit => (i % 2 == 0),
      :allows_publishing => (i % 2 == 0)

  PrerequisiteAnswer.create! :registration => registration,
      :prerequisite => prereq1, :took_course => (i % 2 == 0),
      :waiver_answer => (i % 2 == 0) ? nil :
                        'Silver medal at IOI 2011... bitches'
  PrerequisiteAnswer.create! :registration => registration,
      :prerequisite => prereq2, :took_course => (i % 4 < 2),
      :waiver_answer => (i % 4 < 2) ? nil :
                        'Bronze medal at IMO 2011, A+ in 18.something'
end

# Exams.

exams = (1..3).map do |i|
  exam = Assignment.new :name => "Exam #{i}", :weight => 5.0,
      :deadline => Time.now - 2.weeks - 6.weeks + i * 4.weeks
  exam.deliverables_ready = exam.deadline < Time.now
  exam.metrics_ready = exam.deadline < Time.now 
  exam.course = course
  exam.save!
  metrics = (1..(5 + i)).map do |j|
    AssignmentMetric.create! :assignment => exam, :name => "Problem #{j}",
                             :max_score => 6 + (i + j) % 6
  end
  exam
end

([admin] + users).each_with_index do |user, i|
  exams.each_with_index do |exam, j|
    next unless exam.deadline < Time.now
    exam.metrics.each_with_index do |metric, k|
      next if i + j == k
      Grade.create! :subject => user, :grader => admin, :metric => metric,
          :score => metric.max_score * (0.1 * ((i + j + k) % 10))
    end
  end
end

# Psets.

psets = (1..8).map do |i|
  pset = Assignment.new :name => "Problem Set #{i}", :weight => 1.0,
      :deadline => Time.now - 1.day - 5.weeks + i * 1.week
  pset.course = course
  pset.deliverables_ready = i < 8
  pset.metrics_ready = pset.deadline < Time.now
  pset.save!
  metrics = (1..(2 + i)).map do |j|
    AssignmentMetric.create! :assignment => pset, :name => "Problem #{j}",
                             :max_score => 6 + (i + j) % 6
  end
  
  deliverable = Deliverable.create! :assignment => pset,
      :name => 'PDF write-up',
      :description => 'Please upload your write-up, in PDF format.',
      :filename => 'writeup.pdf'
  ProcChecker.create! :deliverable => deliverable,
      :message_name => :validate_pdf

  pset
end

([admin] + users).each_with_index do |user, i|
  psets.each_with_index do |pset, j|
    next unless pset.deadline < Time.now
    
    writeup = pset.deliverables.first
    pdf = Prawn::Document.new :page_size => 'LETTER', :page_layout => :portrait
    pdf.y = 792 - 36
    pdf.font "Times-Roman"
    pdf.text user.email, :align => :left, :size => 24
    pdf.text user.name, :align => :left, :size => 24
    pdf.text pset.name, :align => :left, :size => 24
    pdf_contents = pdf.render
    
    next if i + j % 20 == 1
    time = pset.deadline - 1.day + i * 1.minute
    submission = Submission.create! :deliverable => writeup, :user => user,
         :db_file_attributes => { :f_file_name => 'writeup.pdf',
             :f_file => pdf_contents, :f_file_size => pdf_contents.length,
             :f_content_type => 'application/pdf' },
         :created_at => time, :updated_at => time
    submission.run_checker
    submission.check_result.update_attributes! :created_at => time + 1.second,
                                               :updated_at => time + 5.seconds
    
    pset.metrics.each_with_index do |metric, k|
      next if i + j == k
      Grade.create! :subject => user, :grader => admin, :metric => metric,
          :score => metric.max_score * (0.1 * ((i + j + k) % 10)),
          :created_at => pset.deadline + 1.day,
          :updated_at => pset.deadline + 1.day
    end
  end
end



# TODO: Projects.

