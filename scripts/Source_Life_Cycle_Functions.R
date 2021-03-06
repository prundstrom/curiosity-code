# Load the C++ functions
#SourceCpp(file.path('cpp_source','should_pick_neighbor.cpp'))



syll_learn <- function (parameters, moranData, select_type = 2, 
                       totally_new = FALSE, randlearn_context = 1, 
                       verbose = FALSE) { 
  
  # select_type decides whether the learning is vertical (2) or oblique (1)
  
  for (population in 1 : parameters$num_pop) {
    # Make the reference objects for the teacher - the indices for the 
    # syllables unique to the teacher's repertoire, and a set of 
    # probabilities for each syllable to be learned
    
    #Vertical Learning;  parameters (set up source_of_ONEs), and considerations
    
    if (select_type == 2) { 
      
      #parameters and considerations for VERTICAL LEARNING
      source_of_ONEs <- which(
        moranData[1, 1:parameters$sylnum, population] == 1) 
        # calls for sylls vertical tutor (father) has

      if(length(source_of_ONEs) == 0) {
        saveRDS(parameters,"parent with no sylls.RData")
        print(moranData[1, 1:parameters$sylnum, population])
        stop("wot? parent has no syllables?!")
      } #address syll loss by stopping script if parent has no sylls

      for(sex in 1 : 2) {
        moranData[(sex + 2), 1:parameters$sylnum, population] <- 0
      } # clear the sylreps rows about to be filled in :D
      
      
    } else { #Oblique Learning; source_of_ONEs setup, and considerations 
      

      # double-check that the tutor isn't out 
      # of sylls before comparing repertoire to pupil.
      source_of_ONEs <- which(
        moranData[5, 1:parameters$sylnum, population] == 1)
      pupil_has_ONEs <- which(
        moranData[3, 1:parameters$sylnum, population] == 1)
      
      if(length(source_of_ONEs) == 0) {
        stop("wot? tutor has no syllables?!")
      }
      
      # as often happens with super self-philes, the tutor may not have 
      # anything new to give the pupil. If this is the case, this skips 
      # to the next step in the for loop.
      #source_of_ONEs <- which(moran$learning.pool[5, , population] == 1)[
        #which(!(which(moran$learning.pool[5, , population] == 1) %in% which(
          #moran$learning.pool[3, , population] == 1)))]
      source_of_ONEs <- setdiff(which(source_of_ONEs==1),which(pupil_has_ONEs == 1))
      if(length(source_of_ONEs) == 0) {
        if(verbose == TRUE) {
          print(paste0("tutor has no syllables for population ", population))
        }
        next} # if curiosity is so low that tutor can teach nothing, just skip 
              # this population's tutor learning step
    } # Oblique Learning parameters and considerations
    #if(randlearn_context == 1) {
    #  teacher.mean <- mean(source_of_ONEs)
    #}
    
    
    #sink(file = paste("syll_learn pop", population, "probs.txt", sep = " "), 
    # append = T)
    #print(probs)
    #sink()
    
    for (sex in 1:select_type) {
      average_rate_randlearn_overlap <- c()
      #print(source_of_ONEs)
      probs <- runif(source_of_ONEs, 0, 1)
      for (sylls_to_learn in 1:length(source_of_ONEs)) {
        # moran$learning.pool[(sex + 2), 
        # source_of_ONEs[sylls_to_learn], population] <- 0
        if(probs[sylls_to_learn] <= (parameters$learnprob[select_type])) {
          moranData[(sex + 2), source_of_ONEs[sylls_to_learn], population] <- 1
        }
        if(probs[sylls_to_learn] > (
          1 - parameters$randlearnprob[select_type])) {
          r_norm <- rnorm(1, mean = ifelse(randlearn_context == 1,
                                           mean(source_of_ONEs),
                                           source_of_ONEs[sylls_to_learn]),
                          sd = parameters$stand.dev)
          if(r_norm > parameters$sylnum) {
            r_norm <- parameters$sylnum
          } else if(r_norm < 1) {
            r_norm <- 1
          }
          #totally_new refers to the idea that if a pupil is learning a sound
          if(totally_new == TRUE) {
            counter <- 1
            r_norm_pool <- rnorm(100, mean = ifelse(randlearn_context == 1,
                                           mean(source_of_ONEs),
                                           source_of_ONEs[sylls_to_learn]),
                                 sd = parameters$stand.dev)

            while(moranData[(sex + 2), floor(r_norm), population] == 1) {

              r_norm <- r_norm_pool[counter]
              if(r_norm > parameters$sylnum) {
                r_norm <- parameters$sylnum
              } else if(r_norm < 1) {
                r_norm <- 1
              }
              counter = counter + 1
            }
            moranData[(sex + 2), floor(r_norm), population] <- 1
            average_rate_randlearn_overlap <- append(average_rate_randlearn_overlap, counter)
          } else {
            moranData[(sex + 2), floor(r_norm), population] <- 1
          }
        }
      }
      if(totally_new == TRUE) {moranData[sex, parameters$sylnum + 5, population] <- mean(average_rate_randlearn_overlap)}
    }
  }
  return(moranData)
}

recordvariable.initialize <- function(P, timestep_fraction, variableID) {
  if (variableID == 1) {
    record.variable <- array(0, c(2, P$num_pop, (P$num_timesteps/timestep_fraction)))
  } else if (variableID == 2) {
    record.variable <- array(0, c((2 * P$num_pop), P$sylnum, (P$num_timesteps/timestep_fraction)))
  } else if (variableID == 3) {
    record.variable <- array(0, c(12, P$num_pop, (P$num_timesteps/timestep_fraction)))
  } else if (variableID == 4) {
    record.variable <- array(0, c((2 * P$num_pop), (P$num_pop * P$one_pop_singers[1]), (P$num_timesteps/timestep_fraction)))
  }
  return(record.variable)
}

variable.archive <- function(parameters, tempData, syllable_object = FALSE, curiosity_object = FALSE, data_container, timestep, specificVariable) {
  #context_name <- c("parents&offspring","replacedindividuals")
  #if(context == 1) {
  # if (!(syllable_object) && (specificVariable == 1) || (specificVariable == 2)) {
  #   stop("if specificVariable = 1 | 2, then syllable_object must exist")
  # } else if ((specificVariable == 3) || (specificVariable == 4) && !(tempData) || !(curiosity_object)) {
  #   stop("if specificVariable = 3 | 4, then tempData and curiosity_object must exist")
  # }
  if (specificVariable == 1) {
    for (population in 1:parameters$num_pop) {
      for (sex in 1:2) {
        #sylrep_rowcol
        data_container[sex, population, timestep] <- mean(rowSums(syllable_object[((1 + ((sex - 1) * (parameters$pop_size / 2))) : (sex * (parameters$pop_size / 2))), , population]))
      }
    }
  
  } else if (specificVariable == 2) {
    for (population in 1:parameters$num_pop) {
      for (sex in 1:2) {
        # sylrep_dstbxn
        data_container[(((population - 1) * 2) + sex), , timestep] <- colSums(syllable_object[((1 + ((sex - 1) * (parameters$pop_size / 2))) : (sex * (parameters$pop_size / 2))), , population])
      }
    }
  } else if (specificVariable == 3) {
    for (population in 1:parameters$num_pop) {
      # curity_mean_t
      data_container[3, population, timestep] <- tempData[2, parameters$sylnum + 3, population]
      data_container[10, population, timestep] <- tempData[3, parameters$sylnum + 3, population]

      for (sex in 1:2) {
        data_container[sex, population, timestep] <- mean(curiosity_object[((1 + ((sex-1) * parameters$pop_size/2)):(sex * parameters$pop_size/2)), population])

        # Individual Curiosity Values
        data_container[(sex + 3), population, timestep] <- tempData[sex, parameters$sylnum + 2, population]
        data_container[(sex + 5), population, timestep] <- tempData[(sex + 2), parameters$sylnum + 2, population]
        data_container[(sex + 7), population, timestep] <- tempData[(sex + 2), parameters$sylnum + 4, population]
        data_container[11, population, timestep] <- tempData[(sex + 2), parameters$sylnum + 5, population]
        data_container[12, population, timestep] <- tempData[sex, parameters$sylnum + 5, population]
      }
    } 
  } else if (specificVariable == 4) {
    for (population in 1:parameters$num_pop) {
      for (sex in 1:2) {
        # curity_repert
        data_container[(sex + ((population - 1) * 2)), , timestep] <- hist(curiosity_object[((1 + ((sex-1) * parameters$pop_size / 2)):(sex * parameters$pop_size / 2)), population], breaks = parameters$curiositybreaks, plot = FALSE)$counts
      }
    }
  }
  return(data_container)
}

make.offspring.calls <- function(parameters, temporMan){
  for(sex in 1:2){
    new_index <- c(sample(parameters$pop_calls_matrix[sex, ], 2, replace=T))
    temporMan[(sex + 2), parameters$sylnum + 1, ] <-  new_index
  }
  return(temporMan)
}


update_selexn_data <- function(main_parameters, temping, suitor_choices, preferred_bird, selector_bird,
                               curiosity_value, selector_population, selection_context, 
                               sylreps_choices, sylrep_selector, selection_count, giving_up = FALSE) {

  selected_pair <- c(suitor_choices[preferred_bird], # Bird being selected
                       selector_bird)          # Bird doing the selecting

  if(!(giving_up)) {
    singer_population <- ceiling(
    preferred_bird/main_parameters$one_pop_singers[selection_context])
    
    sylrep_pairs <- rbind(sylreps_choices[preferred_bird,],
                          sylrep_selector)
  } else {
    singer_population <- selector_population 
    
    sylrep_pairs <- rbind(sylreps_choices, sylrep_selector)
  } # This happens if giving_up == TRUE. Not ideal for tutor selection, 
    # but I guess that's the point of giving up... also, this should 
    # basically NEVER happen for tutor context anyway.

  curiosities <- c(curiosity_value[selected_pair[1],singer_population],
                     curiosity_value[selected_pair[2],selector_population])

  for(bird in 1:selection_context) {
    pool.row <- (5^(2-selection_context)) * bird

    temping[pool.row, main_parameters$sylnum + 1, selector_population] <- selected_pair[bird]
    temping[pool.row, 1:main_parameters$sylnum, selector_population] <- sylrep_pairs[bird,]
    temping[pool.row, main_parameters$sylnum + 2, selector_population] <- curiosities[bird]
  }
  temping[(4 - selection_context), main_parameters$sylnum + 3, selector_population] <- selection_count
  return(temping)
}

should_pick_neighbor <- function(index,total_chances,selection_context,
                                 current_chance, sorted_selections,
                                 selection_filter,preferred_bird,
                                 lower=0,upper=Inf) {
  lower_bound <- round(total_chances[selection_context] * lower)
  upper_bound <- round(total_chances[selection_context] * upper)
  is_desperate <- between(current_chance, lower_bound, upper_bound)
  is_neighbor_better <- sorted_selections[
    preferred_bird+index] %in% selection_filter
  return(is_desperate && is_neighbor_better)
}

score_similarity <- function(suitor_vector, selector_vector) {
  # Standard Deviation Scoring:
  # The basic sylrep comparison caluclation that finds the differences 
  # between the suitor and selector sylreps, then assigns a weighted 
  # value based on suitor syllable distance from median of selector's sylrep.
  selector_median <- median(which(selector_vector == 1))
  vector_diff <- which(suitor_vector-selector_vector != 0)
  AbsVal_diffs <- abs(vector_diff - selector_median)
  
  return(sum(AbsVal_diffs)) 
  # Output: value of similarity/dissimilarity between 
  # sylrep of suitors and selector.
}

sing.selection <- function(parameters, tempMoran, 
                           curiosity_level, select_type, 
                           sylrep_object, 
                           num_select_chances = c(10, 42), 
                           sylrep_fill_chances = 10, 
                           verbose_output = TRUE, 
                           interbreed = FALSE){

  #print("sing.selection beginning")
  for(population in 1 : parameters$num_pop) { #population <- 1 rm(population)
    #print(paste("this is population",population,sep=" "))
    chance_for_selection = 1
    while(chance_for_selection <= num_select_chances[select_type]) {
      stop = FALSE
      if(chance_for_selection == num_select_chances[select_type]) {
        auto.teachers <- matrix(c(sample(parameters$pop_calls_matrix[1, ], 
          sylrep_fill_chances),sample(parameters$pop_calls_matrix[2, ], 
          sylrep_fill_chances)),2,sylrep_fill_chances,T)
        for(MTsylrep_filter in 1:sylrep_fill_chances){
          #c((sample(parameters$pop_calls_matrix[1, ], 1)), (
            #sample(parameters$pop_calls_matrix[2, ], 1)))
          if((
            sum(sylrep_object[auto.teachers[1,MTsylrep_filter
                ], , population]) != 0) && (
            sum(sylrep_object[auto.teachers[2,MTsylrep_filter
                ], , population]) != 0)) {
            if(verbose_output == TRUE) {
              context.name <- c("Tutor", "Mate")
              warning(print(paste0("Automatic Teacher(s) = ", 
                             auto.teachers[,MTsylrep_filter], 
                              " for Population ", population, 
                              " ", context.name[select_type], 
                              " Selection")))
            }

            tempMoran = update_selexn_data(
              parameters, tempMoran, auto.teachers[1,], MTsylrep_filter, 
              auto.teachers[2,MTsylrep_filter], curiosity_level, population, 
              select_type, sylrep_object[auto.teachers[1,],,], 
              sylrep_object[auto.teachers[2,MTsylrep_filter],,population], 
              num_select_chances[select_type], T)
            
            # if(MTsylrep_filter >= 1) {}
            stop = TRUE
            break
          }
        }
        if(stop) {break}
      }
      
      if(select_type == 1) {
        #This statement separates specific mating and tutoring selection 
        # qualities: singSuccessFilter will inform the selection of a 
        # mate by restricting the successful mate to those individuals 
        # from the same population as the selector. Similarly, selector.index
        # distinguishes between mating and tutoring, except here it uses
        # a randomly-selected female for the mating context, and the 
        # offspring for tutoring.
        
        # "1-20"
        singSuccessFilter <- 1 : (
          (parameters$one_pop_singers[select_type]) * (parameters$num_pop)) 
        selector.index <- tempMoran[3, parameters$sylnum + 1, population]

      } else {
        singSuccessFilter <- (1 + ((population - 1) * (
          parameters$one_pop_singers[select_type]))) : (
            population * parameters$one_pop_singers[select_type]) 
            # "1-10," or "11-20"
        selector.index <- sample(parameters$pop_calls_matrix[2, ], 1)
      }
      
      selector.sylrep <- sylrep_object[selector.index, , population]
      #print("sapply")
      selection.index <- (
        # This creates sample calls for each population; 
        # each population has a sample size of parameters$one_pop_singers, 
        # which comes from the male half of the population. probability 
        # defined by the fraction of syllable repertoires of each member of 
        # each population divided by the maximum syllrep of the population.
        vapply(1:parameters$num_pop,
               function(x) {
                 temp <- rowSums(sylrep_object[
                   parameters$pop_calls_matrix[1,],,x])
                 sample(x = parameters$pop_calls_matrix[1,], 
                        size = parameters$one_pop_singers[select_type], 
                        replace = FALSE,
                        prob = temp / max(temp))
                },
               rep(0, parameters$one_pop_singers[select_type])
              )
        ) # probability = the number of times each individual's syllable 
        # repertoire has a 1 in it (sum(sylrep_object[
        # parameters$pop_calls_matrix[1,]])), 
        # divided by the biggest repertoire's total.
      
      # create a matrix of all the sylrep_object of the sample 
      # males from selection.index
      selection.sylreps <- t(
        cbind(
          vapply(
            1:parameters$one_pop_singers[select_type], 
            function(x) {sylrep_object[selection.index[x,1],,1]},
            rep(0, dim(sylrep_object)[2])
          ),
          vapply(
            1:parameters$one_pop_singers[select_type], 
            function(x) {sylrep_object[selection.index[x,2],,2]},
            rep(0, dim(sylrep_object)[2])
          )
        )
      )
      
      # applies the standard deviation scoring to the males in 
      # selection.sylrep_object; larger score means greater
      # difference between male sylrep and selector's sylrep.
      # temp <- apply(X = selection.sylreps, MARGIN = 1,
      #               FUN = score_similarity,
      #               selector_vector = selector.sylrep)
      # golf_score <- sort(apply(X = selection.sylreps, MARGIN = 1,
      #               FUN = score_similarity,
      #               selector_vector = selector.sylrep))$ix
      
      golf_score <- sort(apply(X = selection.sylreps, MARGIN = 1,
                               FUN = score_similarity,
                               selector_vector = selector.sylrep),
                         index.return = T,
                         method = 'radix')$ix
      # orders the scored list of suitors; subsets one suitor from the rest,
      # according to the value of the selector's (auditory) curiosity.
      singer <- golf_score[round(curiosity_level[selector.index, population] *(
        parameters$one_pop_singers[select_type] * parameters$num_pop) + 0.5)]
      if(sum(selection.sylreps[singer,])==0) {
        chance_for_selection = chance_for_selection + 1
        next}
      
      #should_pick_neighbor <- function(index,lower,upper=Inf) {
      
      if(!interbreed) {
        should_continue <- TRUE
        if(singer %in% singSuccessFilter) {
          

          tempMoran = update_selexn_data(
            parameters, tempMoran, selection.index, singer, selector.index, 
            curiosity_level, population, select_type, selection.sylreps, 
            selector.sylrep, chance_for_selection, F)
          
          should_continue <- FALSE
        }
        

        should_pick_neighbor(1, num_select_chances, select_type,
                                    chance_for_selection, golf_score,
                                    singSuccessFilter, singer, lower=0.5,
                                    upper=0.75)

        if(should_continue) {
          for(neighbor in c(1, -1)) {
            if(should_pick_neighbor(neighbor, num_select_chances, select_type,
                                    chance_for_selection, golf_score,
                                    singSuccessFilter, singer, lower=0.5,
                                    upper=0.75)) {
              singer <- golf_score[singer+neighbor]
              
              tempMoran = update_selexn_data(
                parameters, tempMoran, selection.index, singer, 
                selector.index, curiosity_level, population, 
                select_type, selection.sylreps, selector.sylrep,
                chance_for_selection, F)
              
              should_continue <- FALSE
              break
            }
          }
        }
        
        if(should_continue) {
          for(neighbor in c(1, -1, 2, -2)) {
            if(should_pick_neighbor(neighbor,num_select_chances,select_type,chance_for_selection,golf_score,singSuccessFilter,singer,lower=0.75)) {
              singer <- golf_score[singer+neighbor]
              
              moran = update_selexn_data(parameters, moran, selection.index, singer, selector.index, curiosity_level, 
                                         population, select_type, selection.sylreps, selector.sylrep, 
                                         chance_for_selection, F)
              should_continue <- FALSE
              break
            }
          }
        }
        
        if(!should_continue) {
          break
        }
      } else {
        if(sum(sylrep_object[selection.index[singer], , population]) != 0) {
          

          tempMoran = update_selexn_data(
            parameters, tempMoran, selection.index, singer, selector.index, 
            curiosity_level, population, select_type, selection.sylreps, 
            selector.sylrep, chance_for_selection, F)
          
          break
        }
      }
      chance_for_selection = chance_for_selection + 1
    }
  }
  return(tempMoran)
}


curiosity_learn <- function (parameters, 
                             tempObjects, 
                             timestep = single_timestep, 
                             inheritance_pattern = 1) {
  
  curinh_patterns <- array (
    data = c (
      1, 2, 
      1, 2, 
      1, 2, 
      2, 1
    ), 
    dim = c (
      4,2
    ),
    dimnames = list (c ("father", "mother", "same", "opposite"), 
                     c ("male birb", "female birb")
                   )
  )
  # For posterity: 
  #   curinh_patterns <- array(
  #     data = c(1, 2, 1, 2, 1, 2, 2, 1), 
  #     dim = c(4,2), 
  #     dimnames = list(c("father", "mother", "same", "opposite"), 
  #                     c("male birb", "female birb")
  #                    )
  #   ) MAKE BLENDED INHERITANCE OPTION - MAYBE USE ZERO_TO_ONE_TEMPLATE
  newcuriosity <- array(
          data = runif((parameters$num_pop * 2), -1, 1), 
          dim = c(2, parameters$num_pop))
  
  for(population in 1 : (parameters$num_pop)) {
    
    for(sex in 1:2) {
      if(tempObjects[
        curinh_patterns[inheritance_pattern,sex], 
        parameters$sylnum + 2, 
        population
      ] == 0) {stop(
        "not the time for learning curiosity from parents right now...")}
      
      curinh_attempts <- 1

      while((tempObjects[curinh_patterns[
          inheritance_pattern,sex
        ], parameters$sylnum + 2, population] + 
        ((1 - parameters$curlearnprob) * (newcuriosity[sex, population
        ]))) < 0) {

        newcuriosity[sex, population] <- runif(1, 0, 1)
        curinh_attempts <- curinh_attempts + 1
      
      }

      while((tempObjects[curinh_patterns[
        inheritance_pattern,sex
      ], parameters$sylnum + 2, population] + 
      ((1 - parameters$curlearnprob) * (newcuriosity[sex, population
      ]))) > 1) {

        newcuriosity[sex, population] <- runif(1, -1, 0)
        curinh_attempts <- curinh_attempts + 1
      
      }
      
      new.curiosity <- tempObjects[curinh_patterns[
          inheritance_pattern,sex
        ], parameters$sylnum + 2, population] + 
        ((1 - parameters$curlearnprob) * (newcuriosity[sex, population
        ])) # Adding small proportion of noise
      
      tempObjects[
        (sex + 2), parameters$sylnum + 4, population
      ] <- tempObjects[(sex + 2), parameters$sylnum + 2, population]
      tempObjects[
        (sex + 2), parameters$sylnum + 2, population
      ] <- new.curiosity
      tempObjects[
        (sex + 2), parameters$sylnum + 5, population
      ] <- curinh_attempts
    }
  }
  return(tempObjects)
}

recuriosity.offspring <- function(parameters, objectMoran, curiosity_object) {
  for(population in 1:parameters$num_pop) {
    for(sex in 1:2) {
      #index <- moran$pairing.pool[(sex + 2), 1, population]

      # curiosity_level <- array(0, c(P$pop_size, P$num_pop))

      curiosity_object[
        objectMoran[
          (sex + 2), parameters$sylnum + 1, population
        ], population] <- objectMoran[
          (sex + 2), parameters$sylnum + 2, population]
    }
  }
  return(curiosity_object)
}

resylreps.offspring <- function(parameters, moranObjectTemp, sylrep_object) {
  for(population in 1:parameters$num_pop) {
    for(sex in 1:2) {
      #index <- moran$pairing.pool[(sex + 2), 1, population]
      #index_sylrep <- moran$learning.pool[(sex + 2), , population]

      # sylreps <- array(0, c(P$pop_size, P$sylnum, P$num_pop))

      sylrep_object[moranObjectTemp[
        (sex + 2), parameters$sylnum + 1, population
        ], , population] <- moranObjectTemp[
          (sex + 2), 1:parameters$sylnum, population
        ]
    }
  }
  return(sylrep_object)
}


store_timesteps <- function(parameters, filename = thousand_timesteps, 
  record_1, record_2, record_3, record_4, saved_stuff, syll_container, 
  cur_container, run_timedate, FolderName = FolderName){
   # # # #  #directory <- getwd()
  results_directory <- file.path('results')
  if(filename == 1) {
    # run_timedate <- format(Sys.time(), "%F-%H%M%S")
    if(!(dir.exists(file.path(results_directory, saved_stuff$docnamez)))) {
      dir.create(file.path(results_directory, saved_stuff$docnamez))
      dir.create(file.path(results_directory, saved_stuff$docnamez, 
        "variable_store"))
    }
    dir.create(file.path(results_directory, saved_stuff$docnamez, 
      "variable_store", paste0(run_timedate, "-GMT-variable-store")))
    # FolderName <- file.path(results_directory, saved_stuff$docnamez, 
    #   "variable_store", paste0(run_timedate, "-GMT-variable-store"))
    saveRDS(saved_stuff, file.path(FolderName, "metadata.RData"))
  } 
  # else {
  #   FolderName <- readRDS (file.path(
  #       "source", "temp", paste0(
  #         "Foldername_", parameters$simNumber, ".RData")
  # ))}
  

  for(deyteh in 1:4) {
    thing <- c("sylrep_rowcol", "sylrep_dstbxn", 
      "curity_mean_t", "curity_repert")
    file.create(file.path(FolderName, paste0(
      "variable-store-", filename, "-", thing[deyteh], ".RData")))
    if (deyteh == 1) {
      objekshun <- record_1
    } else if (deyteh == 2) {
      objekshun <- record_2
    } else if (deyteh == 3) {
      objekshun <- record_3
    } else if (deyteh == 4) {
      objekshun <- record_4
    }
    # print("tryna save")
    saveRDS(objekshun, file.path(FolderName, paste0(
      "variable-store-", filename, "-", thing[deyteh], ".RData")))
    # print("saved")
  }
  
  saveRDS(FolderName, file.path(
    "source", "temp", paste0(
      "Foldername_", parameters$simNumber, ".RData")))
  saveRDS(parameters, file.path(
    FolderName, "parameters.RData"))
  saveRDS(syll_container, file.path(
    FolderName, "end_sylbls.RData"))
  saveRDS(cur_container, file.path(
    FolderName, "end_cursty.RData"))
  
  return(FolderName)
}
