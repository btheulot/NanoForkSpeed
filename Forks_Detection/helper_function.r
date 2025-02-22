### Helper Function used in Theulot et al 2022

###
simpleRFD <- function(gr,lr=1,na2zero=F,expor=F,outname='myRFDdata')
{
	### L=+ to keep compatibility with OK seq data
	require(GenomicRanges)
	require(rtracklayer)

	bs <- 1

	cv_L <- coverage(gr[strand(gr)=='+'])
	cv_R <- coverage(gr[strand(gr)=='-'])

	cv <- cv_L+cv_R
	RFD <- (cv_R-cv_L)/(cv_R+cv_L)
	lr_index <- which(cv<=lr)
	RFD2 <- RFD
	RFD2[lr_index] <- NA

	naname <- '_wiNA'
	if (na2zero)
	{
		RFD[is.na(RFD)] <- 0
		RFD2[is.na(RFD2)] <- 0
		naname <- '_noNA'
	}

	if (expor)
	{
		export(cv,con=paste0(outname,'_cov_tot_bs',bs/1000,'k_lr',lr,'.bw'))
		export(cv_L,con=paste0(outname,'_cov_2left_bs',bs/1000,'k_lr',lr,'.bw'))
		export(cv_R,con=paste0(outname,'_cov_2right_bs',bs/1000,'k_lr',lr,'.bw'))
		export(RFD2,con=paste0(outname,'_RFD_bs',bs/1000,'k_lr',lr,naname,'.bw'))
	}
	res <- list(cv,cv_L,cv_R,RFD,RFD2)
	names(res) <- c('cv','cv_L','cv_R','RFD','RFD2')
	return(res)
}

##

### a function to check correlation between RFD (or other coverage like type of data)
cor.rfd <- function(a,b,met='s')
{cor(as.numeric(unlist(a)[!is.na(unlist(a)) & !is.na(unlist(b))]),as.numeric(unlist(b)[!is.na(unlist(a)) & !is.na(unlist(b))]),method=met)}
##

### a function to plot forks with NFS informations
plotforks2 <- function(toto,b2a.thr=0.02,fileout,plot.raw=F)
{

	suppressMessages(require(tidyverse))
	require(gridExtra)
	require(RcppRoll)
	theme_set(theme_bw())

	mypal=RColorBrewer::brewer.pal(12,"Paired")
	pl=list()
	for (i in 1:nrow(toto))
	{
		test <- toto %>% dplyr::slice(i)
		if (plot.raw) {
			pl[[i]] <- ggplot(test$signalr[[1]]) +
				geom_point(aes(x=positions,y=Bprob,col="data.raw"),size=0.2,alpha=0.5)+
				geom_text(data=test$sl2[[1]],aes(x=sl.x,y=0,col="RDP_seg_type",label=sl.pat2,fontface="bold"), show.legend = F)+
				geom_line(aes(x=positions,y=signal,col="data.smoothed"))+
				geom_line(data=test$RDP[[1]],aes(x=x,y=y,col="RDP_segment"))+
				geom_hline(yintercept=b2a.thr,linetype="dashed") +
				geom_segment(data=test$forks[[1]],aes(x=X1,xend=X2,y=(0.5+sign(d.Y)/40),yend=(0.5+sign(d.Y)/40),col="NFS_fork_chase"),arrow=arrow(length = unit(0.2,"cm")), show.legend = F)+
				geom_segment(data=test$forks[[1]],aes(x=X0,xend=X1,y=(0.5+sign(d.Y)/40),yend=(0.5+sign(d.Y)/40),col="NFS_fork_pulse"),arrow=arrow(length = unit(0.1,"cm")), show.legend = F)+
				geom_text(data=test$forks[[1]],aes(x=(X0+X1)/2,y=(0.8+sign(d.Y)/20),fontface="bold",col="NFS_speed",label=speed),size=2, show.legend = F)+
				xlab(paste(test$chrom,test$start,test$end,test$strand,test$read_id,sep="_"))+
				guides(col = guide_legend(title = "Legend",override.aes = list(lwd = 1,labels="")))+
				theme(legend.position = "right")+
				scale_color_manual(breaks = c("data.smoothed","data.raw","RDP_segment","RDP_seg_type","NFS_fork_pulse","NFS_fork_chase","NFS_speed","data.gap"),values = mypal[c(2,1,4,3,6,5,8,10)])+
				coord_cartesian(ylim=c(0,1))
		}else{
			pl[[i]] <- ggplot(test$signalr[[1]]) +
				geom_text(data=test$sl2[[1]],aes(x=sl.x,y=0,col="RDP_seg_type",label=sl.pat2,fontface="bold"), show.legend = F)+
				geom_line(aes(x=positions,y=signal,col="data.smoothed"))+
				geom_line(data=test$RDP[[1]],aes(x=x,y=y,col="RDP_segment"))+
				geom_hline(yintercept=b2a.thr,linetype="dashed") +
				geom_segment(data=test$forks[[1]],aes(x=X1,xend=X2,y=(0.5+sign(d.Y)/40),yend=(0.5+sign(d.Y)/40),col="NFS_fork_chase"),arrow=arrow(length = unit(0.2,"cm")), show.legend = F)+
				geom_segment(data=test$forks[[1]],aes(x=X0,xend=X1,y=(0.5+sign(d.Y)/40),yend=(0.5+sign(d.Y)/40),col="NFS_fork_pulse"),arrow=arrow(length = unit(0.1,"cm")), show.legend = F)+
				geom_text(data=test$forks[[1]],aes(x=(X0+X1)/2,y=(0.8+sign(d.Y)/20),fontface="bold",col="NFS_speed",label=speed),size=2, show.legend = F)+
				xlab(paste(test$chrom,test$start,test$end,test$strand,test$read_id,sep="_"))+
				guides(col = guide_legend(title = "Legend",override.aes = list(lwd = 1,labels="")))+
				theme(legend.position = "right")+
				scale_color_manual(breaks = c("data.smoothed","data.raw","RDP_segment","RDP_seg_type","NFS_fork_pulse","NFS_fork_chase","NFS_speed","data.gap"),values = mypal[c(2,1,4,3,6,5,8,10)])+
				coord_cartesian(ylim=c(0,1))
		}
		if (test$gap_pos[[1]]$gap_start[1]>0)
		{
			pl[[i]] <- pl[[i]]+
				geom_segment(data=test$gap_pos[[1]],aes(x=gap_start,xend=gap_end,y=1,yend=1,col="data.gap"),size=4)
		}
	}
	pdf(fileout,height=12)
	if (nrow(toto)>=5)
	{for (j in seq(1,(nrow(toto)),5)[1:(nrow(toto)%/%5)])
	{do.call(grid.arrange,c(pl[j:(j+4)],ncol=1))}
	}
	if (nrow(toto)%%5 >0)
	{
		j=tail(seq(1,(nrow(toto)),5),1)
		do.call(grid.arrange,c(pl[j:(j+nrow(toto)%%5-1)],ncol=1,nrow=5))
	}
	dev.off()
}

##

### plot the distribution of the signal to set the b2a.thr

plot_signal <- function(EXP,xmax=1,EXPname="EXP",bs=1000,minlen=5000,EXP_b2a.thr0=0.02,alldata=F,nreads=NA,saved=T,plotit=F)
{
	suppressMessages(require(kmlShape))
	suppressMessages(require(tidyverse))
	require(ggpubr)
	theme_set(theme_bw())

	myRDP <- function(x,...)
	{
		DouglasPeuckerEpsilon(x$positions,x$signal,epsilon=0.1,spar=NA)
	}


	if (!is.na(nreads) & nrow(EXP)>nreads)
	{
		set.seed(123)
		EXP2 <- sample_n(EXP,nreads)
	}else{
		EXP2 <- EXP
	}

	EXP_NFSall <- EXP2 %>%
		mutate(read_id=map_chr(read_id, function(x) str_remove(x,"read_"))) %>%
		select(read_id,chrom,start,end,strand,signalr) %>%
		mutate(length=end-start) %>%
		filter(length>minlen) %>%
		mutate(RDP=map(signalr,myRDP,RDP.eps=0.1)) %>%
		mutate(RDP.length=map_int(RDP,function(x) nrow(x))) %>%
		mutate(Bmedy=map_dbl(signalr,function(z) median(z$signal)))
	EXP_NFS3 <- EXP_NFSall %>% filter(RDP.length>3)
	# all data
	if (alldata==T) {
		test0 <- EXP_NFSall %>%
			mutate(noise= map(signalr, function(y) {
				y %>%
					mutate(positions = round(positions/bs)*bs) %>%
					group_by(positions) %>%
					summarise(Bmean = mean(signal),.groups = 'drop')%>%
					select(Bmean)
			})) %>%
			select(noise) %>%
			unnest(cols=c(noise))
		signal_plot0 <- ggplot(test0)+
			geom_histogram(aes(x=Bmean),binwidth=0.002,alpha=0.3)+
			geom_vline(aes(xintercept=EXP_b2a.thr0))+
			coord_cartesian(xlim=c(0,xmax))+
			scale_x_continuous(paste0("mean B signal by ",bs/1000,"kb"), breaks=seq(0,xmax,0.1))

		signal_plot1 <- ggplot(test0 %>% filter(Bmean>0.002))+
			geom_histogram(aes(x=Bmean),binwidth=0.002,alpha=0.3)+
			geom_vline(aes(xintercept=EXP_b2a.thr0))+
			coord_cartesian(xlim=c(0.002,xmax/4))+
			scale_x_continuous(paste0("mean B signal by ",bs/1000,"kb"), breaks=seq(0,xmax/4,0.01))+
			theme(axis.text.x = element_text(angle = 45,hjust=1))
		ggarrange(signal_plot0,signal_plot1,nrow=2)
		if (saved==T)
		{ggsave(paste0(EXPname,"_all_1kbmeansignal.pdf"),h=8,w=6)}
	}
	# RDP>3 data
	test1 <- EXP_NFS3 %>%
		mutate(noise= map(signalr, function(y) {
			y %>%
				mutate(positions = round(positions/bs)*bs) %>%
				group_by(positions) %>%
				summarise(Bmean = mean(signal),.groups = 'drop')%>%
				select(Bmean)
		}
		)) %>%
		select(noise) %>% unnest(cols=c(noise))
	signal_plot2 <- ggplot(test1)+
		geom_histogram(aes(x=Bmean),binwidth=0.002,alpha=0.3)+
		geom_vline(aes(xintercept=EXP_b2a.thr0))+
		coord_cartesian(xlim=c(0,xmax))+
		scale_x_continuous(paste0("mean B signal by ",bs/1000,"kb"), breaks=seq(0,xmax,0.1))

	signal_plot3 <- ggplot(test1 %>% filter(Bmean>0.002))+
		geom_histogram(aes(x=Bmean),binwidth=0.002,alpha=0.3)+
		geom_vline(aes(xintercept=EXP_b2a.thr0))+
		coord_cartesian(xlim=c(0.002,xmax/4))+
		scale_x_continuous(paste0("mean B signal by ",bs/1000,"kb"), breaks=seq(0,xmax/4,0.01))+
		theme(axis.text.x = element_text(angle = 45,hjust=1))

	ggarrange(signal_plot2,signal_plot3,nrow=2)
if (saved==T)
	{ggsave(paste0(EXPname,"_RDP3_1kbmeansignal.pdf"),h=8,w=6)}
if (plotit==T) {ggarrange(signal_plot2,signal_plot3,nrow=2)}
}

### my GR shuffling
shuffleGR4=function(seqinf=seqinfS288CrDNA,chrnb=16,inputGR=inputData,gap=Ngaps2)
{	require(GenomicRanges)
	seqname=seqnames(seqinf)

	hit <- inputGR[seqnames(inputGR)==seqname[chrnb]]
	gapchr=gap[seqnames(gap)==seqname[chrnb]]
	# altenative to deal with no gap
	if (length(gapchr)==0) {gapchr=GRanges(seqnames=seqname[chrnb],ranges=IRanges(start=1,width=1),seqinfo=seqinfo(inputGR))}
	ravail <- ranges(gaps(gapchr)[seqnames(gaps(gapchr))==seqname[chrnb] & strand(gaps(gapchr))=="*"])
	#		st_avail <- unlist(as.vector(ravail))
	# broken in BioC3.7, should come back in BioC3.8
	# Temporary fix
	st_avail <- IRanges:::unlist_as_integer(ravail)
	#
	st_rdgr <- sample(st_avail,length(hit))
	if (length(hit)==1)
	{
		wi_rdgr <- width(hit)
	}else{
		wi_rdgr <- sample(width(hit))
		#necessary if only one range sample(width()) choose a number
		#betwen in 1:width() rather than one width
	}
	ra_rdgr <- sort(IRanges(start=st_rdgr,width=wi_rdgr))
	rgap <- ranges(gapchr)
	#sum(overlapsAny(ra_rdgr,ranges(gapchr)))

	keep <- IRanges()
	ra_rdgr2 <- IRanges()
	while ((sum(overlapsAny(ra_rdgr,rgap))!=0) | (sum(overlapsAny(ra_rdgr2,keep))!=0))
	{
		keep <- ra_rdgr[overlapsAny(ra_rdgr,rgap)==0]
		hit2 <- ra_rdgr[overlapsAny(ra_rdgr,rgap)!=0]
		st_rdgr2 <- sample(st_avail,length(hit2))
		if (length(hit2)==1)
		{
			wi_rdgr2 <- width(hit2)
		}else{
			wi_rdgr2 <- sample(width(hit2))
		}
		ra_rdgr2 <- IRanges(start=st_rdgr2,width=wi_rdgr2)
		ra_rdgr <- c(keep,ra_rdgr2)
	}
	rdgr <- sort(GRanges(seqnames=Rle(rep(seqname[chrnb],length(hit))),ranges=ra_rdgr,strand=Rle(rep('*',length(hit))),seqinfo=seqinfo(inputGR)))
	return(rdgr)
}

# function to resample on a genome

shuffleGRgen <- function(dummy=1,seqinf2=seqinfS288CrDNA,inputGR2=inputData,gap2=Ngaps2,chrlist=1:chnb)
{
	rdlist=GRangesList()
	for (i in chrlist) {rdlist[[i]] <- shuffleGR4(seqinf=seqinf2,chrnb=i,inputGR=inputGR2,gap=gap2)}
	y<- do.call(c,rdlist)
	return(y)
}

# Gap annotation
findNgaps <- function(x)
	# x is a DNAString
{ y=Rle(strsplit(as.character(x),NULL)[[1]])
y2=ranges(Views(y,y=='N'))
return(y2)	# y2 is a list of IRanges
}

### a function to change seqinf of a GRanges
NewSeqinfo <- function(GR,seqin) {
	seqlevels(GR,pruning.mode="coarse") <- seqlevels(seqin)
	seqinfo(GR) <- seqin
	return(GR)
}


### plot read length
plot_readlength <- function(EXP,EXP_NFS,fileout=NA,ymax=150000) {
	if (is.na(fileout))
	{
		fileout <- EXP.NFS[[2]]$exp[1]
	}
	toplot <- bind_rows(
		tibble(len=EXP %>% mutate(length=end-start) %>% filter(length>5000) %>% pull(length),leg="All reads >5kb"),
		tibble(len=EXP_NFS[[1]][[1]] %>% pull(length),leg="All reads RDP3"),
		tibble(len=EXP_NFS[[1]][[2]] %>% pull(length),leg="Reads with forks"))
	totext <- toplot %>% group_by(leg) %>% summarise(n=n()) %>% ungroup
	tomed <- toplot %>% group_by(leg) %>% summarise(med=round(median(len),0)) %>% ungroup
	ggplot(toplot)+
		geom_violin(aes(y=len,fill=leg,x=leg),col=NA,scale="width")+
		coord_cartesian(ylim=c(0,ymax))+
		geom_boxplot(aes(y=len,x=leg),outlier.shape=NA,width=0.2)+
		geom_text(data=totext,aes(x=leg,y=0,label=n),fontface="italic") +
		geom_text(data=tomed,aes(x=leg,ymax-1000,label=med),col="red") +
		scale_fill_brewer(palette="Set1")+
		ggtitle(fileout)+
		xlab("Read categories")+
		ylab("Length")
	ggsave(paste0(fileout,"_readlength.pdf"),h=4,w=6)
}

### like sapply with mclapply
smclapply <- function(X, FUN, ...,
											mc.preschedule = TRUE, mc.set.seed = TRUE,
											mc.silent = FALSE, mc.cores = getOption("mc.cores", 2L),
											mc.cleanup = TRUE, mc.allow.recursive = TRUE)
{simplify2array(mclapply(X, FUN, ...,
												 mc.preschedule = mc.preschedule, mc.set.seed = mc.set.seed,
												 mc.silent = mc.silent, mc.cores = mc.cores,
												 mc.cleanup = mc.cleanup, mc.allow.recursive = mc.allow.recursive))}
