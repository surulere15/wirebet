import { motion } from 'framer-motion';

const targets = [
  { title: "Crypto Betting Operators", description: "Secure definitive market positioning and accelerate global user acquisition." },
  { title: "Prediction & Event Markets", description: "Anchor complex forecasting algorithms with a highly accessible consumer identity." },
  { title: "Tokenized Gaming Platforms", description: "Signal institutional-grade execution speed and instantaneous settlement architecture." },
  { title: "Web3 Infrastructure Brands", description: "Deliver comprehensive platform solutions under a tier-one moniker." }
];

export default function StrategicFit() {
  return (
    <section className="py-32 md:py-40 px-6 bg-background flex flex-col items-center border-t border-border">
      <div className="max-w-5xl mx-auto w-full">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.8 }}
          className="text-center flex flex-col items-center mb-24"
        >
          <div className="w-[1px] h-16 bg-white/40 mb-10" />
          <h2 className="text-3xl md:text-4xl font-display font-medium tracking-wide text-white">Target Acquirers</h2>
        </motion.div>

        <motion.div 
          className="grid grid-cols-1 md:grid-cols-2 gap-8"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 1, delay: 0.2 }}
        >
          {targets.map((target, idx) => (
            <div key={idx} className="bg-surface border border-border p-12 hover:border-white/30 hover:bg-surfaceHighlight transition-all duration-500 flex flex-col justify-start min-h-[260px] relative group">
               <div className="w-12 h-12 rounded-none bg-surfaceHighlight border border-border flex items-center justify-center mb-8 group-hover:border-white/40 transition-colors">
                 <div className="w-3 h-3 bg-white/20 group-hover:bg-white transition-colors" />
               </div>
               <h3 className="text-2xl md:text-3xl font-medium tracking-wide text-white mb-5">{target.title}</h3>
               <p className="text-base md:text-lg font-normal text-secondaryText tracking-wide leading-relaxed">{target.description}</p>
            </div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
