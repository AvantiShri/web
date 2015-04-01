use strict;
use warnings;

my $inputFile = $ARGV[0];
my $attributeScoresFile = $ARGV[1];
my $iterations = 100000;
if (!defined($inputFile)) {
	die("Input file should be the first argument. Optionally supply attribute scores file as second argument\n");
}

open INPUTFILE, "< $inputFile";

my $EXPECTING_ATTRIBUTES_STATE = "expectingAttributes";
my $EXPECTING_CLASS_NAME_STATE = "expectingSignName";
my $CLASS_KEY = "sign";
my $ATTRIBUTES_KEY = "attributes";

my %classEntries = ();
my $state = $EXPECTING_CLASS_NAME_STATE;
my $classEntry;
while(<INPUTFILE>) {
	$_ =~ s/\n|\r//g;
	if ($state eq "$EXPECTING_CLASS_NAME_STATE") {
		$classEntry = {};
		my $className = $_;
		$classEntry->{$CLASS_KEY} = $className;
		my $nextLine = <INPUTFILE>; $nextLine =~ s/\n|\r//g;
		if ($nextLine ne "---") {
			die("was expecting sign $className to be followed by a line with ---\n");
		}
		$classEntry->{$ATTRIBUTES_KEY} = [];
		$state = $EXPECTING_ATTRIBUTES_STATE;
	} elsif ($state eq "$EXPECTING_ATTRIBUTES_STATE") {	
		if ($_ eq "XXX") {
			if (scalar(@{$classEntry->{$ATTRIBUTES_KEY}}) == 0) {
				die("sign $classEntry->{$CLASS_KEY} should have had some attributes but none were found\n");
			} else {
				print "For $classEntry->{$CLASS_KEY}, found ".scalar(@{$classEntry->{$ATTRIBUTES_KEY}})." attributes\n";
			}
			$classEntries{$classEntry->{$CLASS_KEY}} = $classEntry;
			$state = $EXPECTING_CLASS_NAME_STATE;
		} else {
			push @{$classEntry->{$ATTRIBUTES_KEY}}, $_;
		}
	} else {
		die("Unsupported state: $state\n");
	}
}
if ($state ne "$EXPECTING_CLASS_NAME_STATE") {
	die("weird...we ended on state $state. Did you forget the termina XXX?\n");
}


my %allAttributes; #use a hasmap to uniquify
my @allClasses;
foreach my $entry(values(%classEntries)) {
	foreach my $attribute(@{$entry->{$ATTRIBUTES_KEY}}) {
		$allAttributes{$attribute} = 1;
	}
	push @allClasses, $entry->{$CLASS_KEY};
}
my @allAttributes = keys(%allAttributes);
#shuffle the list of attributes
foreach my $i(0..$#allAttributes) {
	#select rand index from remaining spots
	my $randIndex = int(rand()*(scalar(@allAttributes)-$i)); 
	my $chosenAttribute = $allAttributes[$randIndex];
	#swap
	$allAttributes[$randIndex] = $allAttributes[$i];
	$allAttributes[$i] = $chosenAttribute;
}

my %attributeScores;
my $SCORE_KEY = "scoreKey";

if (!defined($attributeScoresFile)) {
	my $count = 0;
	open OUT, "> attributeScores.txt";

	print "-------------\nPlease score each attribute\n-------------\n";
	foreach my $attribute(@allAttributes) {
		$count++;
		print "Attribute: $attribute ($count/".scalar(@allAttributes).")\n";
		my $score = <STDIN>;
		$score =~ s/\n|\r//g;
		while ($score !~ /^\d+(\.\d+)?$/) {
			print ("Please enter a number\n");
			$score = <STDIN>; $score =~ s/\n|\r//g;
		}
		$attributeScores{$attribute} = {$ATTRIBUTES_KEY => $attribute, $SCORE_KEY => $score};
		print OUT "$attribute\t$score\n";
	}
} else {
	open ATTRIBUTE_SCORES, "< $attributeScoresFile\n";
	while (<ATTRIBUTE_SCORES>) {
		$_ =~ s/\n|\r//g;
		my ($attribute,$score) = split(/\t/,$_);
		$attributeScores{$attribute} = {$ATTRIBUTES_KEY => $attribute, $SCORE_KEY => $score};
	}
}


@allClasses = sort {$a cmp $b} @allClasses;

print "Please select a sign:\n";
foreach my $i(0..$#allClasses) {
	print "$i: $allClasses[$i]\n";
}
my $selectedClass = <STDIN>; $selectedClass =~ s/\n|\r//g;
while ($selectedClass !~ /\d+/ || $selectedClass < 0 || $selectedClass > $#allClasses) {
	print "Please enter an integer from 0 to $#allClasses\n";
	$selectedClass = <STDIN>; $selectedClass =~ s/\n|\r//g;
}
$selectedClass = $allClasses[$selectedClass];
print "\nThe attributes for $selectedClass are:\n";
my @attributesForSelectedClass = @{$classEntries{$selectedClass}->{$ATTRIBUTES_KEY}};
$" = "\n";
my $targetScore = 0;
foreach my $attributeForSelectedClass(@attributesForSelectedClass) {
	my $score = $attributeScores{$attributeForSelectedClass}->{$SCORE_KEY};
	print "$attributeForSelectedClass: $score\n";
	$targetScore += $score;
}
print "\nTotal score: $targetScore\n";

print "\nPerforming $iterations iterations of monte carlo\n";
my $numToSample = scalar(@attributesForSelectedClass);
my $hitsWithGreaterScore = 0;
open MONTECARLO, "> monteCarlo.txt";
foreach my $i(1..$iterations) {
	#sample numToSample without replacement
	my $totalScore = 0;
	foreach my $i(0..($numToSample-1)) {
		#select rand index from remaining spots
		my $randIndex = int(rand()*(scalar(@allAttributes)-$i)); 
		my $chosenAttribute = $allAttributes[$randIndex];
		#swap
		$allAttributes[$randIndex] = $allAttributes[$i];
		$allAttributes[$i] = $chosenAttribute;
		$totalScore += $attributeScores{$chosenAttribute}->{$SCORE_KEY};
	}
	if ($totalScore >= $targetScore) {
		$hitsWithGreaterScore += 1;
	}
	print MONTECARLO "$totalScore\n";
}

print "$hitsWithGreaterScore trials had a score >= $targetScore\n";






