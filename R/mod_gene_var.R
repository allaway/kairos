# Module UI

#' @title   mod_gene_variant_ui and mod_gene_variant_server
#' @description  A shiny Module.
#'
#' @param id shiny id
#' @param input internal
#' @param output internal
#' @param session internal
#'
#' @rdname mod_gene_variant
#'
#' @keywords internal
#' @export 
#' @importFrom shiny NS tagList 
mod_gene_variant_ui <- function(id){
  ns <- NS(id)

    tagList(
      
      h2("Gene Variant Profiles"),
      box(h4('Module Summary'), 
          p("This module can be used to visualize the various types of genetic variants found in samples selected in the cohort builder and their positions on the presumptive protein structure. The top panel shows a lollipop plot where each lollipop is a known variant in one of the samples. The bottom panel is an oncoplot where each column is a sample and each row corresponds to the variants in the selected genes."),
 width = 12),
      
      # selectizeInput(ns("studyName"), label = "Study Name", choices = unique(kairos::exome_data$study),
      #                selected = unique(kairos::exome_data$study), multiple = T),
      # 
      box(title = "Samples in the selected cohort", 
          width = 12,
          solidHeader = T,
          status = "primary",
          shiny::textOutput(ns('sample_check'))),
      
      
      box(title = "Positional information of variants in tumor samples", 
          status = "primary", 
          solidHeader = TRUE,
          width = 12,
          collapsible = FALSE,
          shiny::selectizeInput(ns("Genes"), label = "Genes", choices = unique(kairos::jhu_tumor_file@data$Hugo_Symbol),
                                selected = "NF1", multiple = F),
          shiny::plotOutput(ns('lollipop_plot'))),
    
      box(title = "Oncoplot of your favorite genes in the selected tumor samples", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        #height = 6,
        collapsible = FALSE,
        shiny::selectizeInput(ns("Selected_Genes"), label = "Selected Genes (Please choose multiple genes for plotting)", choices = unique(kairos::jhu_tumor_file@data$Hugo_Symbol),
                              selected = c("NF1", "TP53"), multiple = T),
        shiny::plotOutput(ns('onco_plot')))
    
    )
}

# Module Server

#' @rdname mod_gene_variant
#' @export
#' @keywords internal

mod_gene_variant_server <- function(input, output, session, specimens){
  ns <- session$ns
  
  output$sample_check <- shiny::renderText({
    
    tumor_sample_bc <- as.vector(kairos::jhu_tumor_file@data$Tumor_Sample_Barcode[kairos::jhu_tumor_file@clinical.data$specimenID %in% 
                                                                                    specimens()])
    
      if(length(tumor_sample_bc)>0) {
      file_with_specimen <- maftools::subsetMaf(kairos::jhu_tumor_file, tsb = c(tumor_sample_bc))
      base::ifelse(all(specimens() %in% file_with_specimen@clinical.data$specimenID),
                   "All samples in your selected cohort have genomic variant data. They are plotted below",
                   "Only a subset of selected cohort has genomic variant data. They are plotted below.")
    } else(
      print("No variant data found. Please modify your cohort.")
    )

  })
  
  output$lollipop_plot <- shiny::renderPlot({
   
    tumor_sample_bc <- as.vector(kairos::jhu_tumor_file@data$Tumor_Sample_Barcode[kairos::jhu_tumor_file@clinical.data$specimenID %in% specimens()])
    
    validate(need(length(tumor_sample_bc)>0, "No variant data found. Please modify your cohort."))
    
    file_with_specimen <- maftools::subsetMaf(kairos::jhu_tumor_file, tsb = c(tumor_sample_bc))
    
    #Changing colors for variant classifications 
    coolors = c("#ca054d", "#3b1c32", "#a4d4b4", "#ffcf9c", "#007EA7", "#EAF27C", "#F2AA7E", "#9984D4", "#C5979D")
    names(coolors) = c('Frame_Shift_Del',
                       'Frame_Shift_Ins',
                       'Nonsense_Mutation', 
                       'Multi_Hit', 
                       'Missense_Mutation',
                       'In_Frame_Ins', 
                       'Splice_Site', 
                       'In_Frame_Del')

    
    maftools::lollipopPlot(
      file_with_specimen,
      gene = input$Genes,
      AACol = NULL,
      labelPos = NULL,
      labPosSize = 0.9,
      showMutationRate = TRUE,
      showDomainLabel = TRUE,
      cBioPortal = FALSE,
      refSeqID = NULL,
      proteinID = NULL,
      repel = FALSE,
      collapsePosLabel = TRUE,
      legendTxtSize = 1.5,
      labPosAngle = 0,
      domainLabelSize = 1.5,
      axisTextSize = c(1, 1),
      printCount = FALSE,
      colors = coolors,
      labelOnlyUniqueDoamins = TRUE,
      defaultYaxis = FALSE,
      titleSize = c(1.2, 1),
      pointSize = 2.5
    )
    
    
  })
  

  output$onco_plot <- shiny::renderPlot({
  
    tumor_sample_bc <- as.vector(kairos::jhu_tumor_file@data$Tumor_Sample_Barcode[kairos::jhu_tumor_file@clinical.data$specimenID %in% specimens()])
  
    validate(need(length(tumor_sample_bc)>0, "No variant data found. Please modify your cohort."))
    validate(need(length(input$Selected_Genes)>1, "This plot requires multiple genes as input. Please add other genes to your selection."))
  
    file_with_specimen_oncoplot <- maftools::subsetMaf(kairos::jhu_tumor_file, tsb = c(tumor_sample_bc))
    
    #Changing colors for variant classifications 
    coolors = c("#ca054d", "#3b1c32", "#a4d4b4", "#C5979D", "#007EA7", "#EAF27C", "#F2AA7E", "#9984D4")
    names(coolors) <- c('Frame_Shift_Del',
                       'Frame_Shift_Ins',
                   'Nonsense_Mutation', 
                   'Multi_Hit', 
                   'Missense_Mutation',
                   'In_Frame_Ins', 
                   'Splice_Site', 
                   'In_Frame_Del')
    
    #Color coding for Annotation
    
    col1 <- c("#f6511d", "#ffb400", "#00a6ed", "#7fb800", "#0d2c54")
    col2 <- c("#6da34d", "#56445d", "#548687", "#8fbc94", "#c5e99b")
   
    names(col1) <- as.vector(unique(kairos::jhu_tumor_file@clinical.data$tumorType))
    names(col2) <- as.vector(unique(kairos::jhu_tumor_file@clinical.data$sampleType))
    
    col1 <- list(tumorType = col1)
    col2 <- list(sampleType = col2)
    
  
    maftools::oncoplot(file_with_specimen_oncoplot,
                     #top=2,
                     genes = c(input$Selected_Genes),
                     drawRowBar = TRUE,
                     drawColBar = FALSE,
                     colors = coolors,
                     clinicalFeatures = c("tumorType", "sampleType"),
                     sortByAnnotation = TRUE,
                     annotationColor = c(col1,col2), 
                     #groupAnnotationBySize = FALSE,
                     includeColBarCN = TRUE,
                     removeNonMutated = FALSE, 
                     fill = TRUE,
                     logColBar = FALSE,
                     SampleNamefont = 5,
                     annotationFontSize = 1.5, 
                     fontSize = 1,
                     sepwd_genes = 1.0,
                     sepwd_samples = 0.5,
                     legendFontSize = 1.8,
                     titleFontSize = 1.8, 
                     keepGeneOrder = TRUE, 
                     GeneOrderSort = TRUE, 
                     bgCol = "gray", 
                     borderCol = "white")
  

})

}

## To be copied in the UI
# mod_gene_variant_ui("gene_variant_ui")

## To be copied in the server
# callModule(mod_gene_variant_server, "gene_variant_ui")

