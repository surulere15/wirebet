import { motion } from 'framer-motion';

export default function Hero() {
  return (
    <section className="min-h-screen bg-black flex flex-col justify-center items-center px-6 relative">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.5, ease: "easeOut" }}
        className="z-10 w-full max-w-4xl mx-auto flex flex-col items-center text-center"
      >
        <h1 className="text-6xl md:text-8xl lg:text-[9rem] font-display font-medium text-white tracking-[0.1em] mb-6">
          WIREBET
        </h1>

        <h2 className="text-[11px] md:text-xs uppercase tracking-[0.3em] text-zinc-400 font-medium mb-6">
          PREDICTION MARKETS POWERED BY CRYPTO
        </h2>
        
        <p className="text-sm md:text-base text-primaryText max-w-md font-sans font-normal leading-loose tracking-wide mb-14">
          A premium brand positioned at the intersection of crypto infrastructure and event markets.
        </p>
        
        <div className="flex flex-col items-center gap-4 w-full max-w-[280px]">
          <a href="#" className="w-full py-4 border border-white/60 text-white font-medium text-xs tracking-[0.2em] uppercase hover:bg-white hover:text-black transition-colors duration-500 text-center">
            STRATEGIC ACCESS
          </a>
          <a href="#" className="w-full py-4 border border-white/10 text-zinc-400 font-medium text-xs tracking-[0.2em] uppercase hover:border-white/30 hover:text-white transition-colors duration-500 text-center">
            DOWNLOAD BRIEF
          </a>
        </div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 2, delay: 0.5 }}
        className="absolute bottom-12 left-0 w-full text-center"
      >
        <span className="text-[9.5px] text-microCopy uppercase tracking-[0.36em] font-medium">
          PRIVATE INVESTMENT, PARTNERSHIP, AND ACQUISITIONS DISCUSSIONS ONLY.
        </span>
      </motion.div>
    </section>
  );
}
