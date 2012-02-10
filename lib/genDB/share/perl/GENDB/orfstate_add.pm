########################################################################
#
# This module defines extensions to the automagically created file
# orfstate.pm. Add your own code below.
#
########################################################################

$VERSION = 1.3;

1;

#
# $Id: orfstate_add.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $
#
# $Log: orfstate_add.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.7  2002/12/18 13:53:23  blinke
# fixed errors in database lock code
#
# Revision 1.6  2002/12/18 13:20:37  blinke
# added LOCKing code to lock() method
#
# Revision 1.5  2002/03/26 14:30:40  blinke
# improved handling of orfstate->orf and orfstate->tool connection
#
# Revision 1.4  2001/10/12 12:53:21  agoesman
# checked for GENDB release Version 1.0.5
#
# Revision 1.3  2001/10/09 15:29:16  blinke
# added methods to count job in different states
#
# Revision 1.2  2001/05/29 11:23:41  blinke
# added class methods to retrieve number of jobs in different categories (finished, executing, waiting etc)
#
#

##################################################
#           GENDB locking basics :               #
#                                                #
# Running jobs are locked to prevent other       #
# processes to modify and/or rerun this job      #
#                                                #
# lock() locks a job (== sets date_done to 1)    #
#                                                #
# after sucessfully running a job, the process   #
# uses finish() to indicate this state           #
# finish() sets date_done to the current date    #
# these jobs won't be rerun automatically again  #
#                                                #
# if execution of a job failed, the process      #
# calls unlock(). this job can be rerun          #
# the next time the scheduler is updated         #
# unlock() sets date_done to 0, the ready-to-run #
# job state                                      #
##################################################


#####################
# lock a job to run #
#####################
sub lock{
    my ($self)=@_;

    # obtain a write lock for the orfstate table
    $GENDB_DBH->do('LOCK TABLE orfstate WRITE');

    # current lock state
    my $sth = $GENDB_DBH->prepare('SELECT date_done FROM orfstate where id='.
				  $self->id);
    $sth->execute;

    my ($current_lock_state) = $sth->fetchrow_array;
    $sth->finish;
    if ($current_lock_state != 0) {
	$GENDB_DBH->do('UNLOCK TABLES');
	# already locked or done
	return 1;
    }
    else { # not locked
	$self->date_done(1); # lock it
	$GENDB_DBH->do('UNLOCK TABLES');
	return 0;  # exit ok
    };
};


################
# unlock a job #
################
sub unlock {
    my ($self)=@_;
    if ($self->date_done == 1) {
	# job is locked, so unlock it
	$self->date_done (0);
	return 0;
    } elsif ($self->date_done == 0) {
	# job has been unlocked already
	return 0;
    };

    # this job seems to be finished - don't touch it
    return 1;
};


##################################
# set time when job was finished #
##################################
sub finished{
    my ($self)=@_;

    $self->date_done(time());

    return 0;
};


#####################################################
# this function assumes that the job queue is empty #
# it collects all orfstate objects where date_done  #
# is NULL or 1                                     #
######################################################
sub fetch_failed_jobs {
    my ($self) = @_;

    return $self->fetchbySQL("date_done IS NULL or date_done=0 or date_done=1");
};

##############################################################
# check whether an orfstate for a given orf/tool combination #
# exists and return it                                       #
##############################################################
sub check_job {
    my ($self, $orf, $tool) = @_;
    return ${$self->fetchbySQL(sprintf ("orf_id=%d AND tool_id=%d"),
			       $orf->id, $tool->id)}[0];
}

##############################################################
# returns all orfstate for a given orf                       #
##############################################################
sub fetchby_orf {
    my ($self, $orf) = @_;
    my $states = $self->fetchbySQL(sprintf "orf_id=%d", $orf->id);
    my $result = {};
    foreach (@$states) {
	$result->{$_->tool_id} = $_;
    }
    return $result;
}

##############################################################
# returns all orfstate for a given tool                      #
##############################################################
sub fetchby_tool {
    my ($self, $tool) = @_;
    my $states = $self->fetchbySQL(sprintf "tool_id=%d", $tool->id);
    my $result = {};
    foreach (@$states) {
	$result->{$_->orf_id} = $_;
    }
    return $result;
}

###########################
# delete by orf
#
# deletes all orfstates associated to a given orf
#
#########################
sub delete_by_orf {
    my ($class, $orf) = @_;
    
    if (ref $orf) {
	$GENDB_DBH->do("delete from orfstate where orf_id=".$orf->id);
    }
}

#########################
# delete by tool
#
# deletes all orfstates associated to a given tool
#
#########################
sub delete_by_tool {
    my ($class, $tool) = @_;
    
    if (ref $tool) {
	$GENDB_DBH->do("delete from orfstate where tool_id=".$tool->id);
    }
}

###############################################
# return the number of orfstates (the number of #
# all jobs, finished, done and being executed)  #
#################################################
sub number_of_jobs {
    my ($class) = @_;

    my $number=0;
    
    # get number of entries in table orfstate
    my $sth = $GENDB_DBH->prepare('SELECT count(*) FROM orfstate');
    $sth->execute;
    
    ($number) = $sth->fetchrow_array;

    return $number;
};    


####################################################
# return the number of orfstates for finished jobs #
####################################################
sub number_of_finished_jobs {
    my ($class) = @_;

    my $number=0;
    
    # get number of entries in table orfstate which are finished
    # => date_done != 0, date_done != NULL, date_done != 1
    my $sth = 
	$GENDB_DBH->prepare('SELECT count(*) FROM orfstate WHERE date_done != 0 AND date_done != 1 AND date_done IS NOT NULL');
    $sth->execute;
    
    ($number) = $sth->fetchrow_array;

    return $number;
};


################################################################
# returns the number of orfstates for currently executing jobs #
################################################################
sub number_of_executing_jobs {
    my ($class) = @_;

    my $number=0;
    
    # get number of entries in table orfstate which are executing
    # => date_done = 1
    my $sth = 
	$GENDB_DBH->prepare('SELECT count(*) FROM orfstate WHERE date_done = 1');
    $sth->execute;
    
    ($number) = $sth->fetchrow_array;

    return $number;
};


##################################################################
# returns the number of orfstates for jobs waiting for execution #
##################################################################
sub number_of_unfinished_jobs {
    my ($class) = @_;

    my $number=0;
    
    # get number of entries in table orfstate which are waiting for execution
    # => date_done = 0, date_done = NULL
    my $sth = 
	$GENDB_DBH->prepare('SELECT count(*) FROM orfstate WHERE date_done = 0 OR date_done IS NULL');
    $sth->execute;
    
    ($number) = $sth->fetchrow_array;
    
    return $number;
};
