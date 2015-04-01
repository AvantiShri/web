#!usr/bin/perl
use strict;
use warnings;

my $inputFile = $ARGV[0];

if (!defined($inputFile)) {
	die("Please supply the path to the input file of jokes. Usage is: 'perl insideJokes.pl path/to/example_joke_file.txt'\n"); 
}

open INPUT, "< $inputFile\n";

my $QUESTION_KEY = 'question';
my $EXPECTING_BRAND_NEW_QUESTION_STATE = 'expectingBrandNewQuestionState';
my $EXPECTING_NEXT_LINE_IN_QUESTION_STATE = 'expectingNextLineInQuestionState';
my $ANSWERS_KEY = 'answers';
my $RIGHT_ANSWER_KEY = 'rightAnswer';
my $EXPECTING_ANSWERS_STATE = 'expectingAnswers';
my $EXPLANATION_KEY = 'explanation';
my $EXPECTING_EXPLANATION_STATE = 'expectingExplanation';

my @entries;

my $state = $EXPECTING_BRAND_NEW_QUESTION_STATE;;
my $entryBeingFormulated = {};
while(<INPUT>) {
	$_ =~ s/\n|\r//dg;
	if ($state eq $EXPECTING_NEXT_LINE_IN_QUESTION_STATE || $state eq $EXPECTING_BRAND_NEW_QUESTION_STATE) {
		if ($_ =~ /^\-+/) {
			if (!defined($entryBeingFormulated->{$QUESTION_KEY})) {
				die("Hmm. Was expecting a question, but got to the line of dashes before I read the question (line $.)\n");
			}
			$state = $EXPECTING_ANSWERS_STATE;
		} else {
			if (!defined($entryBeingFormulated->{$QUESTION_KEY})) {
				$entryBeingFormulated->{$QUESTION_KEY} = $_;
			} else {
				$entryBeingFormulated->{$QUESTION_KEY} .= "\n$_";
			}
			if ($state eq $EXPECTING_BRAND_NEW_QUESTION_STATE) {
				$state = $EXPECTING_NEXT_LINE_IN_QUESTION_STATE;
			}
		}
	} elsif ($state eq $EXPECTING_ANSWERS_STATE) {
		if ($_ =~ /^\-+/) {
			if (!defined($entryBeingFormulated->{$ANSWERS_KEY})) {
				die("Hmm. Was expecting a list of possible answers, but got to the dashes before I found them (line $.)\n");
			}
			if (!defined($entryBeingFormulated->{$RIGHT_ANSWER_KEY})) {
				die("Hmm. Was expecting at least one of the answers to be prefixed with 'Ans:' to indicate that it was the right answer, but got to the dashes before I found it (line $. for question: $entryBeingFormulated->{$QUESTION_KEY})\n");
			}
			$state = $EXPECTING_EXPLANATION_STATE;
		} else {
			if (lc($_) =~ /^ans:/) {
				$_ =~ s/[Aa][Nn][Ss]://;
				$entryBeingFormulated->{$RIGHT_ANSWER_KEY} = $_;
			}
			push @{$entryBeingFormulated->{$ANSWERS_KEY}}, $_;
		}
	} elsif ($state eq $EXPECTING_EXPLANATION_STATE) {
		if ($_ =~ /^XXX+/) {
			if (!defined($entryBeingFormulated->{$EXPLANATION_KEY})) {
				die("Hmm. Was expecting an explanation, but got to the XXX's indicating the next entry before I found it: $_\n");
			}
			push @entries, $entryBeingFormulated;
			$entryBeingFormulated = {};
			$state = $EXPECTING_BRAND_NEW_QUESTION_STATE;
		} else {
			if (!defined($entryBeingFormulated->{$EXPLANATION_KEY})) {
				$entryBeingFormulated->{$EXPLANATION_KEY} = $_;
			} else {
				$entryBeingFormulated->{$EXPLANATION_KEY} .= "\n$_";
			}	
		}
	}
}
if ($state ne $EXPECTING_BRAND_NEW_QUESTION_STATE) {
	die("Hmm...the file seems to have ended in the middle of an entry defintion. At the point where the file ended, I was in a state of $state and the value that I had for the question was: $entryBeingFormulated->{$QUESTION_KEY}\n. Note that the file format is: [question][line of dashes: ---][any number of possible answer lines, prefixed with Ans: if the correct answer. One line per answer.][line of dashes: ---][explanation][line of capital exes: XXX][repeat]. The last line in the file should be the XXX's\n");
}

close INPUT;

my $score = 0;
my $entriesSoFar = 0;
foreach my $entry(@entries) {
	$entriesSoFar += 1;
	if ($entriesSoFar > 1) {
		print("Your score so far is $score/".($entriesSoFar-1)."; there are a total of ".scalar(@entries)." questions. Hit enter to continue"); <STDIN>;
	}
	my $question = $entry->{$QUESTION_KEY};
	my $rightAnswer = $entry->{$RIGHT_ANSWER_KEY};
	my $explanation = $entry->{$EXPLANATION_KEY};
	print "$question\n";
	
	my $counter = 0;
	foreach my $ans(@{$entry->{$ANSWERS_KEY}}) {
		$counter += 1;
		print("$counter: $ans\n");
	}
	
	my $invalidResponse = 1;
	print("Enter number of response: ");
	my $ans;
	while($invalidResponse) {
		$ans = <STDIN>;
		$ans =~ s/\n|\r//g;
		if (!defined($ans) || $ans !~ /^\d+$/ || $ans > $counter) {
			print "Please enter a number between 1 and $counter: ";
		} else {
			$invalidResponse = 0;
		}
	}
	if ($entry->{$ANSWERS_KEY}->[$ans-1] eq $rightAnswer) {
		$score += 1;
		print("Correct!\n");
	} else {
		print(":-(\nThe correct answer was $rightAnswer\n");
	}
	print "$explanation\n";
}
print "That's it! Your final score is $score/".scalar(@entries)."\n";



